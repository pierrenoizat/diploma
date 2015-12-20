class DeedsController < ApplicationController
  before_action :set_deed, only: [:show, :edit, :update, :destroy, :download, :log_hash]

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
    @json_tx = @deed.op_return_tx
    @deed.tx_hash = @json_tx["hash"]
    @deed.save
    redirect_to @deed, notice: "Deed was successfully logged. OP_RETURN Tx ID is #{@json_tx["hash"]}"
  end

  # GET /deeds
  # GET /deeds.json
  def index
    @deeds = Deed.all
  end

  # GET /deeds/1
  # GET /deeds/1.json
  def show
    
    @user = User.find_by_id(@deed.user_id)
    
    s3 = AWS::S3.new(
    :access_key_id     => Rails.application.secrets.access_key_id,
        :secret_access_key => Rails.application.secrets.secret_access_key
    )

    bucket = s3.buckets['hashtree-assets']
    object = bucket.objects[@deed.avatar_file_name]

    @md5 = Digest::MD5.hexdigest object.read
    
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

    respond_to do |format|
      if @deed.save
        # TODO use Digest::SHA256.file("X11R6.8.2-src.tar.bz2").hexdigest for now, using Paperclip MD5 fingerprint of the file.
        # Digest::MD5.hexdigest(File.read("data"))
        
        s3 = AWS::S3.new(
        :access_key_id     => Rails.application.secrets.access_key_id,
            :secret_access_key => Rails.application.secrets.secret_access_key
        )

        bucket = s3.buckets['hashtree-assets']
        object = bucket.objects[@deed.avatar_file_name]
        # send_data object.read, filename: @deed.avatar_file_name, type: "application/json", disposition: 'attachment', stream: 'true', buffer_size: '4096'
        @md5 = Digest::MD5.hexdigest object.read
        
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
    
    @deed.avatar = nil
    @deed.save # destroy attachment first
    
    @deed.delete
    respond_to do |format|
      format.html { redirect_to root_url, notice: 'Deed was successfully destroyed.' }
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
      params.require(:deed).permit(:name, :user_id, :category, :description, :avatar, :avatar_fingerprint)
    end
    
end
