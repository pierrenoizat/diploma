source 'https://rubygems.org'
ruby '2.4.2'
gem 'rails', '4.2.8'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'jbuilder', '~> 2.0'

gem "cocaine", "= 0.5.7" # required for imagemagick
gem 'aws-sdk', '1.6.9'
gem 'paperclip', '4.2.1'

gem 'google-api-client', '~> 0.7.1'

gem 'launchy', '>= 2.1.1'

gem 'will_paginate', '~> 3.0.6'
gem 'mechanize'

gem 'bitcoin-ruby', git: 'https://github.com/lian/bitcoin-ruby', branch: 'master', require: 'bitcoin'
gem 'money-tree'
gem 'btcruby', '~> 1.6'

gem 'sendgrid-ruby'
gem 'gibbon'

gem 'zeroclipboard-rails'
gem 'prawn', :git => "https://github.com/prawnpdf/prawn.git", :ref => '8028ca0cd2'
gem 'mail_form' # for contact form
gem 'email_validator'
gem 'figaro'
gem "resque", :require => 'resque/server'
gem 'redis'
gem 'redis-store'
gem 'resque_mailer'

gem "activerecord-postgis-adapter", "3.0.0.beta1" 
gem 'blockcypher-ruby'
gem 'nokogiri','~> 1.8.2'
gem 'puma'

group :development, :test do
  gem 'byebug'
  # gem "factory_girl_rails", "~> 4.0"
  gem 'factory_bot'
end
group :development do
  gem 'web-console', '~> 2.0'
  gem 'spring'
  gem 'guard-minitest', '~> 2.3.2' # https://github.com/guard/guard-minitest
  # Colorize minitest output and show failing tests instantly.
  gem 'minitest-colorize', git: 'https://github.com/ysbaddaden/minitest-colorize'
  gem 'terminal-notifier-guard', '~> 1.6.4' # https://github.com/Springest/terminal-notifier-guard
  gem 'terminal-notifier', '~> 1.6.2' # https://github.com/alloy/terminal-notifier
end

gem 'bootstrap-sass'
gem 'high_voltage'
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'pg', '~> 0.18'
gem 'simple_form'

group :development do
  gem 'better_errors'
  gem 'quiet_assets'
  gem 'rails_layout'
end
group :production do
  gem 'rails_12factor'
  gem 'unicorn'
end
