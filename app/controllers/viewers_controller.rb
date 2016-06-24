class ViewersController < ApplicationController
  before_action :set_viewer, only: [:show, :edit, :update, :destroy, :verify]
  
  def verify
      Deed.find_by_id(@viewer.deed_id).signed_email(@viewer.email)
      redirect_to @viewer, notice: "Signed email was sent successfully to #{@viewer.email}."
  end
  
  # GET /viewers
  # GET /viewers.json
  def index
    @viewers = Viewer.all
    unless current_user.admin?
      redirect_to current_user # , alert: 'Access reserved to admin only.'
    end
  end

  # GET /viewers/1
  # GET /viewers/1.json
  def show
    @deed = Deed.find_by_id(@viewer.deed_id)
  end

  # GET /viewers/new
  def new
    @viewer = Viewer.new
    unless current_user.admin?
      redirect_to current_user # , alert: 'Access reserved to admin only.'
    end
  end

  # GET /viewers/1/edit
  def edit
  end

  # POST /viewers
  # POST /viewers.json
  def create
    @viewer = Viewer.new(viewer_params)
    # @viewer.access_key = [id.to_s, SecureRandom.hex(10)].join
    @user = current_user
    respond_to do |format|
      if @viewer.save
        @deed = Deed.find_by_id(@viewer.deed_id)
        @viewer.addition_email
        format.html { redirect_to @deed, notice: 'Viewer was successfully added.' }
        format.json { render :show, status: :created, location: @viewer }
      else
        format.html { redirect_to @user, alert: 'Viewer already authorized or invalid email.' }
        format.json { render json: @viewer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /viewers/1
  # PATCH/PUT /viewers/1.json
  def update
    respond_to do |format|
      if @viewer.update(viewer_params)
        format.html { redirect_to @viewer, notice: 'Viewer was successfully updated.' }
        format.json { render :show, status: :ok, location: @viewer }
      else
        format.html { render :edit }
        format.json { render json: @viewer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /viewers/1
  # DELETE /viewers/1.json
  def destroy
    @viewer.destroy
    respond_to do |format|
      format.html { redirect_to viewers_url, notice: 'Viewer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_viewer
      # @viewer = Viewer.find(params[:id])
      @viewer = Viewer.find_by_access_key(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def viewer_params
      params.require(:viewer).permit(:access_key, :email, :deed_id)
    end
end
