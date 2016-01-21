class DeedsController < ApplicationController
  before_action :authenticate_user!, except: [:download_sample]
  before_action :set_deed, only: [:show, :edit, :update, :destroy, :download, :log_hash, :download_sample]
  
  require 'google/api_client'
  require 'google/api_client'
  require 'google/api_client/client_secrets'
  require 'google/api_client/auth/file_storage'
  require 'google/api_client/auth/installed_app'
  require 'logger'
  
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
      redirect_to @deed, notice: "Our wallet is empty, a previous tx has yet to be confirmed or tx broadcast is temporarily disabled. Please broadcast tx again later."
    end
  end

  # GET /deeds
  # GET /deeds.json
  def index
    @deeds = Deed.all
    redirect_to current_user
  end

  # GET /deeds/1
  # GET /deeds/1.json
  def show
    
    @user = User.find_by_id(@deed.user_id)
    
  end

  # GET /deeds/new
  def new
    @deed = Deed.new
  end

  # GET /deeds/1/edit
  def edit
  end

  # POST /deeds
  # POST /deeds.json
  def create
    
    @deed = Deed.new(deed_params)
    
    require 'digest'
    require 'openssl'

    respond_to do |format|
      if @deed.save
        # TODO use Digest::SHA256.file("X11R6.8.2-src.tar.bz2").hexdigest for now, using Paperclip MD5 fingerprint of the file.
        # Digest::MD5.hexdigest(File.read("data"))
        
        # TODO send PGP signed message to prove origin/ownership of the OP_RETURN tx
        # signing key must match the output spent to create the OP_RETURN tx
        
        s3 = AWS::S3.new(
        :access_key_id     => Rails.application.secrets.access_key_id,
        :secret_access_key => Rails.application.secrets.secret_access_key
        )

        key = 's3-object-key'

        # Creates a string key - store this!
        symmetric_key = OpenSSL::Cipher::AES256.new(:CBC).random_key
        puts symmetric_key

        options = { :encryption_key => symmetric_key }
        # s3_object = s3.buckets[bucket].objects[key]

        # Writing an encrypted object to S3
        # s3_object.write(data, options)

        # Reading the object from S3 and decrypting
        # puts s3_object.read(options)

        bucket = s3.buckets['hashtree-assets']
        object = bucket.objects[@deed.avatar_file_name]
        @deed.upload = Digest::SHA256.hexdigest object.read
        # @deed.avatar_fingerprint = Digest::SHA256.hexdigest s3_object.read(options)
        @deed.save
        
        format.html { redirect_to @deed, notice: 'Deed was successfully created.' }
        format.json { render :show, status: :created, location: @deed }
      else
        format.html { render :new }
        format.json { render json: @deed.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /deeds/1
  # PATCH/PUT /deeds/1.json
  def update
    respond_to do |format|
      if @deed.update(deed_params)
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
    
    @deed.avatar = nil
    @deed.save # destroy attachment first
    
    @deed.delete
    respond_to do |format|
      format.html { redirect_to @user, notice: 'Deed was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use before_action callbacks to share common setup or constraints between actions.
    def set_deed
      @deed = Deed.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def deed_params
      params.require(:deed).permit(:name, :user_id, :category, :description, :avatar, :avatar_fingerprint, :issuer, :tx_hash, :tx_raw, :upload)
    end
    
end
