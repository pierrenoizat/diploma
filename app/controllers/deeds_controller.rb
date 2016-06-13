class DeedsController < ApplicationController
  before_action :authenticate_user!, except: [:new, :download_sample, :download, :show, :verify, :public_display]
  before_action :set_deed, only: [:show, :edit, :update, :destroy, :download, :log_hash, :download_sample, :verify, :public_display, :display_tx]
  
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

    bucket = s3.buckets['hashtree-assets']
    object = bucket.objects[@deed.avatar_file_name]
    
    send_data object.read, filename: @deed.avatar_file_name, disposition: 'attachment', stream: 'true', buffer_size: '4096'
    
  end
  

  def download
    
    s3 = AWS::S3.new(
    :access_key_id     => Rails.application.secrets.access_key_id,
    :secret_access_key => Rails.application.secrets.secret_access_key
    )

    bucket = s3.buckets['hashtree-assets']
    object = bucket.objects[@deed.avatar_file_name]
    
    send_data object.read, filename: @deed.avatar_file_name, disposition: 'attachment', stream: 'true', buffer_size: '4096'
    
  end
  
  
  def log_hash
    
    if @deed.tx_raw.blank?
        
      @raw_transaction = @deed.op_return_tx

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
  
  def address_utxo_count
        
      @deed.tx_raw = @deed.authentication_tx
      @deed.save
    unless @deed.tx_raw.blank?
      redirect_to @deed, notice: "Tx was successfully built."
    else
      redirect_to @deed, notice: "Our wallet is empty, a previous tx has yet to be confirmed or something else prevented us from building the tx. Please try again later."
    end
  end

  # GET /deeds
  # GET /deeds.json
  def index
    @deeds = Deed.all
    redirect_to current_user
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
      redirect_to current_user, alert: 'Access denied: you are not authorized to edit this deed.'
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
    @batches = @issuer.batches
  end

  # POST /deeds
  # POST /deeds.json
  def create

    @deed = Deed.new(deed_params)
    
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
        puts symmetric_key

        options = { :encryption_key => symmetric_key }

        bucket = s3.buckets['hashtree-assets']
        object = bucket.objects[@deed.avatar_file_name]

        @deed.upload = Digest::SHA256.hexdigest object.read
        @deed.save
        @deed.confirmation_email
        
        format.html { redirect_to @deed, notice: 'Deed was successfully created.' }
        format.json { render :show, status: :created, location: @deed }
      else
        flash[:error] = @deed.errors[:base]
        format.html { render :new, notice: 'Deed could not be saved: user not authorized by issuer.' }
        format.json { render json: @deed.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deeds/1
  # PATCH/PUT /deeds/1.json
  def update
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
