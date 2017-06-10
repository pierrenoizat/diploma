require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'money-tree'
# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Diploma
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true
    
    AWS.config(access_key_id: Rails.application.secrets.access_key_id, secret_access_key: Rails.application.secrets.secret_access_key, region: 'eu-west-1', bucket: 'hashtree-assets')
    
    config.paperclip_defaults = {
                :storage => :s3,
                :s3_host_name => 's3-eu-west-1.amazonaws.com'
     }
    
  end
end

$PER_PAGE = 50
# Find admin_uid of André Boussac as env variable

$BROADCAST = true # set to false to prevent transactions from being broadcast, only seen in the logs then.
$MAX_SIZE = 7999 # maximum deed (avatar) file size, in kilobytes

# $NETWORK_FEE = 10000  # in satoshis, i.e 0.0001 BTC, Bitcoin network miners fee applied when sending the op_return tx.
$NETWORK_FEE = 100000 # in satoshis, 10 000 satoshis is around 5 cts with current € exchange rate as of 6/6/2016.

$GOOGLE_DRIVE_URL = "https://www.googleapis.com/upload/drive/v2/files?uploadType=media" # simple file upload

$BLOCKR_BLOCK_URL = "http://btc.blockr.io/api/v1/block/info/"  # used to get block hash for given block height

$BLOCKR_ADDRESS_URL = "http://btc.blockr.io/api/v1/address/info/"
# $BLOCKR_ADDRESS_URL = "http://btc.blockr.io/api/v1/address/info/198aMn6ZYAczwrE5NvNTUMyJ5qkfy4g3Hi?confirmations=0"

$BLOCKR_ADDRESS_UNSPENT_URL = "http://btc.blockr.io/api/v1/address/unspent/"
# $BLOCKR_ADDRESS_UNSPENT_URL = "http://btc.blockr.io/api/v1/address/unspent/1NiA6V8Ges2vEkSx11X5oo2aCyTsCv3XH3?multisigs=1"

$BLOCKR_ADDRESS_BALANCE_URL = "http://btc.blockr.io/api/v1/address/balance/"

$BLOCKR_TX_URL = "http://btc.blockr.io/api/v1/tx/info/"

$BLOCKR_RATES_URL = "http://btc.blockr.io/api/v1/exchangerate/current"

$WEBBTC_TX_URL = "http://webbtc.com/tx/"

$PUSH_TX_URL = "https://api.blockcypher.com/v1/btc/main/txs/push"

$OP_RETURN_AMOUNT = 0.001 # in BTC, 1000 bits or 0.001 BTC or 0.50 € with 1 BTC = 500 €
# $SUGGESTED_USD_AMOUNT = 0.05
# string = "#{$BLOCKR_RATES_URL}"
# @agent = Mechanize.new

# begin
#  page = @agent.get string
# rescue Exception => e
#  page = e.page
# end

# data = page.body
# we convert the returned JSON data to native Ruby
# data structure - a hash
# result = JSON.parse(data)
# usd_base_rate = result['data'][0]['rates']
# $SUGGESTED_BTC_AMOUNT = $SUGGESTED_USD_AMOUNT*usd_base_rate["BTC"].to_f

$PAYMENT_ADDRESS_PATH = "m/1/3" # address where utxos are funded from, currently 1Axoqagyjn5RXcNyLP144dzzYUppTKkB6L in dev and 13iriEcc5Bws3JLmx1NcRYe5rophT9xfdP in prod
$COLLECTION_ADDRESS_PATH = "m/1/4" # we could be using capital M for "public-key only" node

# comment out these lines if problems with rake or rails generate in dev mode

@master = MoneyTree::Master.from_bip32(Rails.application.secrets.mpk) # comment out this line if problems
@payment_node = @master.node_for_path "M/1/3" # comment out this line if problems
$PAYMENT_ADDRESS = @payment_node.to_address # comment out this line if problems
@collection_node = @master.node_for_path "M/1/4" # comment out this line if problems
$COLLECTION_ADDRESS = @collection_node.to_address # comment out this line if problems

$PAYMENT_NODES_COUNT = 2 # payment nodes funded from master payment address and used as inputs in op returns txs, preventing unconfirmed/unspent conflicts.
# number of utxos prepared for a school on a single address
# Payment node i has path "m/2/#{i}"
# TODO fund payment nodes and automate refill from master payment address
# TODO cycle through payment nodes when creating op return txs
# TODO option to send email to user upon op return tx logged successfully
# $PRINT_PDF_LOGO_PATH = "#{::Rails.root.to_s}/public/logo_paymium_128x57.png"
# $PRINT_PDF_LOGO_PATH = "#{::Rails.root.to_s}/public/Logo_ESILV_275x85.png"

module RailsPatch22584
  def insert_fixture(fixture, table_name)
    # A regression with rails 4.2.5 breaks fixtures with symbol keys, specifically this one method.
    # So, stringify keys in the fixture hash being sent to this method.
    super(fixture.stringify_keys, table_name)
  end
end

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.include(RailsPatch22584)