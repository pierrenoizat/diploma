class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user?, :except => [:index]

  def index
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
    @deeds = @user.deeds.paginate(:page => params[:page], :per_page => 3)
  end

end
