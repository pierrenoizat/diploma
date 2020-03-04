Rails.application.config.middleware.use OmniAuth::Builder do
 provider :google_oauth2, Rails.application.secrets.google_omniauth_key, Rails.application.secrets.google_omniauth_secret, {:skip_jwt => true, :scope => 'email,profile'}
end
