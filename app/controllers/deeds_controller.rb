class DeedsController < ApplicationController
  before_action :authenticate_user!, except: [:new, :download_sample, :download, :show, :verify, :public_display, :download_report, :index]
  before_action :set_deed, only: [:show, :edit, :update, :destroy, :download, :log_hash, :download_sample, :verify, :public_display, :display_tx, :download_report]
  
  #require 'google/api_client'
  #require 'google/api_client/client_secrets'
  #require 'google/api_client/auth/file_storage'
  #require 'google/api_client/auth/installed_app'
  #require 'logger'
  
  def verify
      @deed.signed_email(current_user.email)
      redirect_to current_user, notice: "Signed email was sent successfully to #{current_user.email}."
  end
  
  def download_sample
    
    s3 = AWS::S3.new(
    :access_key_id     => Rails.application.secrets.access_key_id,
    :secret_access_key => Rails.application.secrets.secret_access_key
    )

    bucket = s3.buckets[$AWS_S3_BUCKET_NAME]
    object = bucket.objects[@deed.avatar_file_name]
    unless object
      bucket = s3.buckets[$AWS_S3_BUCKET_NAME]
      object = bucket.objects[@deed.avatar_file_name]
    end
    send_data object.read, filename: @deed.avatar_file_name, disposition: 'attachment', stream: 'true', buffer_size: '4096'
    
  end
  
  def download_report
    
    if @deed.batch
      Deed.all.each do |deed|
        if deed.description == @deed.batch.payment_address
    
          s3 = AWS::S3.new(
          :access_key_id     => Rails.application.secrets.access_key_id,
          :secret_access_key => Rails.application.secrets.secret_access_key
          )

          bucket = s3.buckets[$AWS_S3_BUCKET_NAME]
          object = bucket.objects[deed.avatar_file_name]
          unless object
            bucket = s3.buckets[$AWS_S3_BUCKET_NAME]
            object = bucket.objects[deed.avatar_file_name]
          end
    
          send_data object.read, filename: deed.avatar_file_name, disposition: 'attachment', stream: 'true', buffer_size: '4096'
        end
      end
    end 
  end
  

  def download
    # Ruby SDK - Version 1
    s3 = AWS::S3.new(
    :access_key_id     => Rails.application.secrets.access_key_id,
    :secret_access_key => Rails.application.secrets.secret_access_key
    )

    bucket = s3.buckets[$AWS_S3_BUCKET_NAME]
    object = bucket.objects[@deed.avatar_file_name]
    unless object
      bucket = s3.buckets[$AWS_S3_BUCKET_NAME]
      object = bucket.objects[@deed.avatar_file_name]
    end
    
    send_data object.read, filename: @deed.avatar_file_name, disposition: 'attachment', stream: 'true', buffer_size: '4096'
    
  end
  
  
  def log_hash
    if @deed.tx_raw.blank?
      if @deed.batch
        @raw_transaction = @deed.batch_tx
      else
        @raw_transaction = @deed.op_return_tx
      end

    else
      @deed.broadcast_tx
    end
    unless @deed.tx_hash.blank?
      redirect_to @deed, notice: "Deed was successfully logged. OP_RETURN Tx ID is: #{@deed.tx_hash}"
    else
      @deed.tx_raw = ""
      @deed.save
      redirect_to @deed, notice: "Our wallet is empty, a previous tx has yet to be confirmed or tx broadcast is temporarily disabled. Please broadcast tx again later."
    end
  end

  # GET /deeds
  # GET /deeds.json
  def index
    @batch = Batch.find(params[:batch_id])
    @deeds = Deed.all
    result = 0
    unless (params[:first].size < 2 or params[:last].size < 2)
      @deeds = Deed.search(params[:first], params[:last]).order("created_at DESC")
      if @deeds.count > 0
        @deeds.each do |deed|
          if deed.description.include? params[:last] and deed.batch_id == params[:batch_id][0].to_i # keep only match over 10 chars min WITHIN batch
            subs = deed.description.dup # dup will keep deed.description from being modified by slice!
            subs.slice! params[:last]
            if ((subs.include? params[:first]) and ((params[:first].size + params[:last].size) > deed.description.size - 6))
              result += 1
              @deed = deed
            end
            # render :public_display
          end
        end
        if result == 1
          render :public_display # Successfull search
        else 
          redirect_to search_batch_path(@batch), alert: "Search result: zero match or duplicates found."
        end
      else
        redirect_to search_batch_path(@batch), alert: "Search result: not found. Make sure that first name is in lowercase, last name in uppercase (capital letters)."
      end
    else
      redirect_to search_batch_path(@batch), alert: "Search result: invalid query."
    end
    
  end
  
  def display_tx
    redirect_to @deed # TODO code method
  end
  
  def public_display
    
  end

  # GET /deeds/1
  # GET /deeds/1.json
  def show
    @user = User.find_by_id(@deed.user_id)
    @issuer = Issuer.find_by_id(@deed.issuer_id)
    if @deed.upload.blank?
      @deed.update(upload: @deed.avatar_fingerprint)
    end
    
    if @user != current_user
      if current_user
        redirect_to current_user, alert: 'Access denied: you are not authorized to edit this deed.'
      else
        redirect_to root_url, alert: 'Access denied: you are not authorized to edit this deed.'
      end
    end
    
  end

  # GET /deeds/new
  def new
    @deed = Deed.new
    @issuer = Issuer.find_by_id(current_user.issuer_id)
    
    @issuers = [ Issuer.find_by_name(current_user.email) ]
    if @issuer.blank?
      @issuer = Issuer.find_by_name(current_user.email)
    end
    
    if current_user.credit < 1
      redirect_to current_user, alert: 'Insufficient credit: please contact the administrator.'
    end
    
  end

  # GET /deeds/1/edit
  def edit
    @issuer = @deed.issuer
    @batches = []
    @issuer.batches.each do |batch|
      first_block = first_block(batch.payment_address)
      
      # remove batch if that file is already included in batch
      a = batch.deeds.select { |m| m.upload == @deed.upload }
      if a.count > 0
        # @issuer.batches.delete(batch)
        puts 'Diploma is already included in a batch of the School.'
        redirect_to @deed, alert: "Diploma is already included in the "+"#{batch.title} batch of the School."
      end
      
      unless (first_block < 840000 and first_block > 0) # unless batch is already logged in the blockchain
        # include batch in @batches: deeds can be added to this batch
        @batches << batch
      end
      
    end
    @batches = @batches.sort_by { |batch| batch.created_at }
  end

  # POST /deeds
  # POST /deeds.json
  def create

    @deed = Deed.new(deed_params)
    
    if deed_params["category"] == "diploma_report"
      unless (deed_params["description"] =~ /^[a-zA-Z1-9]{27,35}$/)
        redirect_to current_user, alert: 'Description of a diploma report must be a Bitcoin address.'
        return
      end
    end
    
    require 'digest'
    require 'openssl'

    respond_to do |format|
      if @deed.save
        
        current_user.credit -= 1
        current_user.save
        
        s3 = AWS::S3.new(
        :access_key_id     => Rails.application.secrets.access_key_id,
        :secret_access_key => Rails.application.secrets.secret_access_key
        )

        key = 's3-object-key'

        # Creates a string key - store this!
        symmetric_key = OpenSSL::Cipher::AES256.new(:CBC).random_key
        # puts symmetric_key

        options = { :encryption_key => symmetric_key }

        bucket = s3.buckets[$AWS_S3_BUCKET_NAME]
        object = bucket.objects[@deed.avatar_file_name]
        unless object
          bucket = s3.buckets[$AWS_S3_BUCKET_NAME]
          object = bucket.objects[@deed.avatar_file_name]
        end

        @deed.upload = Digest::SHA256.hexdigest object.read
        @deed.save
        # @deed.confirmation_email # TODO fix issue with mailchimp (or revert to sendgrid)
        
        format.html { redirect_to @deed, notice: 'Deed was successfully created.' }
        format.json { render :show, status: :created, location: @deed }
      else
        @deed = Deed.new
        @issuer = Issuer.find_by_id(current_user.issuer_id)

        @issuers = [ Issuer.find_by_name(current_user.email) ]
        if @issuer.blank?
          @issuer = Issuer.find_by_name(current_user.email)
        end

        if current_user.credit < 1
          redirect_to current_user, alert: 'Insufficient credit: please contact the administrator.'
        end
        flash[:error] = @deed.errors[:base]
        format.html { redirect_to current_user, alert: 'Deed could not be saved: invalid/empty deed or user not authorized by issuer.' }
        format.json { render json: @deed.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deeds/1
  # PATCH/PUT /deeds/1.json
  def update
    @issuer=@deed.issuer
    @batches = @issuer.batches
    @batches = @batches.sort_by { |batch| batch.created_at }
    @deed.batch_id = @batches.last.id
    respond_to do |format|
      if @deed.update(deed_params.except(:user_id))
        format.html { redirect_to @deed, notice: 'Deed was successfully updated.' }
        format.json { render :show, status: :ok, location: @deed }
      else
        format.html { render :edit }
        format.json { render json: @deed.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /deeds/1
  # DELETE /deeds/1.json
  def destroy
    
    @user = User.find_by_id(@deed.user_id)
    
    @deed.viewers.each do |viewer|
      viewer.delete
    end
    
    @deed.avatar = nil
    @deed.save # destroy attachment first
    
    @deed.delete
    respond_to do |format|
      format.html { redirect_to @user, notice: 'Deed was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

    def set_deed
      @deed = Deed.find_by_access_key(params[:id])
    end

    def deed_params
      params.require(:deed).permit(:access_key,:issuer_id, :batch_id, :user_id, :name, :category, :description, :avatar, :avatar_fingerprint, :issuer, :tx_hash, :tx_raw, :upload, viewers_attributes: [:access_key, :deed_id, :email])
    end
    
end
