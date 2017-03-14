Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_deliveries = true
  # Uncomment this to test e-mails in development mode
   config.action_mailer.delivery_method = :smtp

  config.exceptions_app = self.routes
  
  # ActionMailer::Base.smtp_settings = {
  config.action_mailer.smtp_settings = {
    :address => "smtp.gmail.com",
    :port => 587,
    :domain => "google.com",
    :authentication => "plain",
    :user_name => "authenticated.diplomas", # email will be sent from btcloans@gmail.com
    :password => Figaro.env.mail_password,
    :enable_starttls_auto  => true # changed from true 27 april 2013
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true
  
  Paperclip.options[:command_path] = "/usr/local/bin/"
  
  $ROOT_URL = "http://localhost:3000"
  $SCHOOLS = ["TEST SCHOOL", "ESILV", "CDI", "TEST", "ESILV 2014", "ESILV 2015", "Test School"]
  $STUDENTS_COUNT = 4
  
  # $AWS_S3_BUCKET_NAME = "hashtree-assets"
  $AWS_S3_BUCKET_NAME = "hashtree-test"
  
  # AWS.config(access_key_id: Rails.application.secrets.access_key_id, secret_access_key: Rails.application.secrets.secret_access_key, region: 'eu-central-1', bucket: 'hashtree-assets')
  AWS.config(access_key_id: Rails.application.secrets.access_key_id, secret_access_key: Rails.application.secrets.secret_access_key, region: 'eu-west-1', bucket: "#{$AWS_S3_BUCKET_NAME}")
  config.paperclip_defaults = {
              :storage => :s3,
              :s3_host_name => 's3-eu-west-1.amazonaws.com'
   }
  
end
