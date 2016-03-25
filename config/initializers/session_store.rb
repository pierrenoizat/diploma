# Be sure to restart your server when you modify this file.
if Rails.env.production? 
  Rails.application.config.session_store :cookie_store, key: '_diploma_session', domain: 'diploma.report'
else
  Rails.application.config.session_store :cookie_store, key: '_diploma_session', domain: 'localhost'
end
