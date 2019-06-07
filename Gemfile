source 'https://rubygems.org'

ruby '2.5.3'
gem 'rails', '~> 5.2.2'
gem 'sass-rails'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails'
gem 'jquery-rails'
gem "cocaine", "= 0.5.7" # required for imagemagick
gem 'aws-sdk'
gem 'paperclip'
gem 'google-api-client', '~> 0.7.1'
gem 'launchy', '>= 2.1.1'
gem 'will_paginate', '>= 3.1'
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
gem 'blockcypher-ruby'
gem 'nokogiri','~> 1.8.2'
gem 'puma'
gem 'bootstrap-sass'
gem 'high_voltage'
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'pg', '~> 0.18'
gem 'simple_form'
gem 'sprockets', '~>3.7.2'
gem "binding_of_caller"

gem 'rails_12factor', group: :production

group :development, :test do
  gem 'byebug'
  gem 'factory_bot'
end
group :development do
  gem 'guard-minitest', '~> 2.3.2' # https://github.com/guard/guard-minitest
  # Colorize minitest output and show failing tests instantly.
  gem 'minitest-colorize', git: 'https://github.com/ysbaddaden/minitest-colorize'
  gem 'terminal-notifier-guard', '~> 1.6.4' # https://github.com/Springest/terminal-notifier-guard
  gem 'terminal-notifier', '~> 1.6.2' # https://github.com/alloy/terminal-notifier
end

group :development do
  gem 'better_errors'
  gem 'rails_layout'
end
group :production do
  gem 'rails_12factor'
  gem 'unicorn'
  gem 'newrelic_rpm'
end
