class SessionsController < ApplicationController

  def new
    redirect_to '/auth/google_oauth2'
  end

  def create
    auth = request.env["omniauth.auth"]
    user = User.where(:provider => auth['provider'],
                      :uid => auth['uid'].to_s).first || User.create_with_omniauth(auth)
    reset_session
    session[:user_id] = user.id
    
    issuer_exist = false
    @issuers=Issuer.all
    @issuers.each do |issuer|
      if (issuer.name == user.email)
        issuer_exist = true
      end
    end
    unless (issuer_exist or (user.credit == 0))
      @issuer = Issuer.create(:name => user.email, :mpk => Rails.application.secrets.mpk)
      user.issuer_id = nil
      user.save
    end
    
    redirect_to root_url, :notice => 'Signed in!'
  end

  def destroy
    reset_session
    redirect_to root_url, :notice => 'Signed out!'
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end

end
