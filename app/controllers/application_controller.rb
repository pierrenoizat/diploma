class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :user_signed_in?, :current_user_admin?
  helper_method :correct_user?, :utxo_addresses, :balance, :address_utxo_count
  helper_method :broadcast, :first_block, :block_height, :input?
  
  include Bitcoin::Builder  
  
  def input?(address, tx_hash)
    # returns true if address is an input of tx (as input 0)
    boole = false
    string = "https://blockchain.info/rawaddr/" + address
    @agent = Mechanize.new
    begin
      page = @agent.get string
    rescue Exception => e
      page = e.page
    end
    data = page.body
    result = JSON.parse(data)
    n = result["n_tx"]
    i = n-1
    block = 840000
    while i > 0
      puts boole
      tx = result["txs"][i]
      if tx["inputs"][0]["prev_out"]["addr"] == address
        if tx_hash == tx["hash"]
          boole = true
          i = 0
        else
          i -= 1
        end
      else
        i -= 1
      end
    end
    boole
  end
  
  
  def first_block(address)
    # returns first block (oldest) where address can be found in a transaction inputs as input 0
    # fetch all txs for address
    string = "https://blockchain.info/rawaddr/" + address
    @agent = Mechanize.new
    begin
      page = @agent.get string
    rescue Exception => e
      page = e.page
    end

    data = page.body
    result = JSON.parse(data)
    n = result["n_tx"]
    i = n-1
    block = 840000
    while i > 0
      tx = result["txs"][i]
      if tx["inputs"][0]["prev_out"]["addr"] == address
        tx_hash = tx["hash"]
        block = [ block, block_height(tx_hash)].min
        puts "According to Blockchain.info, Tx hash: #{tx_hash}"
        puts block
        i = 0
      else
        i -= 1
      end
    end
    if block > 840000
      puts "In no Block as input yet"
    end
    block
    
  end # of first_block helper
  
  
  def block_height(tx_hash)
  
    @agent = Mechanize.new
    string = "http://api.blockcypher.com/v1/btc/main/txs/" + tx_hash #  if blockr.io is unavailable, use blockcypher
    page = @agent.get string
    data = page.body
    result = JSON.parse(data)
    result["block_height"]
     
  end # of block_height helper
  
  
  def broadcast(signed_raw_transaction)
    # TODO check that this method is unused
    # $PUSH_TX_URL = "https://api.blockcypher.com/v1/btc/main/txs/push"
    uri = URI.parse($PUSH_TX_URL)  # param is "tx"
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json'})
      
    data = {"tx": signed_raw_transaction}
    request.body = data.to_json
    response = http.request(request)  # broadcast transaction using $PUSH_TX_URL
    post_response = JSON.parse(response.body)
    puts post_response
    if post_response["error"]
      @tx_id = "Due to malleability issue, Tx ID is not confirmed yet. Broadcast tx again later: #{signed_raw_transaction}"
    else
      @tx_id = "Confirmed Tx ID: #{post_response["tx"]["hash"]}"
    end
    puts @tx_id

    signed_raw_transaction
    
  end # of broadcast helper_method
  
  
  def balance(address)
    # returns balance of address in satoshis
    require "blockcypher"
    block_cypher = BlockCypher::Api.new(api_token: Figaro.env.blockcypher_api_token)
    block_cypher.address_balance(address)["balance"].to_i
  end
  
  def address_utxo_count(address)
    # returns count ( < $STUDENTS_COUNT) of utxos available to fund OP_RETURN transactions from single address (school class diplomas).
    require "blockcypher"
    block_cypher = BlockCypher::Api.new(api_token: Figaro.env.blockcypher_api_token)
    block_cypher.address_balance(address)["n_tx"] # number of txs (spent and unspent)
    
    # string = "https://blockchain.info/rawaddr/" + address
    require "mechanize"
    string = "https://api.blockcypher.com/"+ "#{$API_VERSION}/" + "#{$COIN}/" + "#{$CHAIN}/" + "/addrs/" + address + "?unspentOnly=1"
    # string = "https://api.blockcypher.com/v1/btc/main" + "/addrs/" + address
    @agent = Mechanize.new
    begin
      page = @agent.get string
    rescue Exception => e
      page = e.page
    end

    data = page.body
    result = JSON.parse(data)
    result["txrefs"].count
  end
  
  
  def utxo_addresses(id)
    # returns an array of $PAYMENT_NODES_COUNT unspent addresses available to fund OP_RETURN transactions
    @issuer = Issuer.find_by_id(id)
    @addresses =[]

    @master = MoneyTree::Master.from_bip32(@issuer.mpk)
    i = 1
    while (i <= $PAYMENT_NODES_COUNT)
     
      payment_node = @master.node_for_path "M/2/#{i}" # using capital M for public key only node

      payment_address = payment_node.to_address

      if ( balance(payment_address) > $NETWORK_FEE )
        @addresses << payment_address
      end
      
      i += 1
    end # while
 
    puts "Available addresses: #{@addresses}"
    puts "#{i-1} Addresses scanned."
    return @addresses
  end


  private
    def current_user
      begin
        @current_user ||= User.find(session[:user_id]) if session[:user_id]
      rescue Exception => e
        nil
      end
    end

    def user_signed_in?
      return true if current_user
    end
    
    def current_user_admin?
      current_user.uid == Rails.application.secrets.admin_uid.to_s
    end

    def correct_user?
      @user = User.find_by_id(params[:id])
      (current_user == @user) or (current_user.uid == Rails.application.secrets.admin_uid.to_s)
      # unless ((current_user == @user) or (current_user.uid == Rails.application.secrets.admin_uid))
        #redirect_to root_url, :alert => "Access denied."
      # end
    end

    def authenticate_user!
      if !current_user
        redirect_to root_url, :alert => 'You need to sign in for access to this page.'
      end
    end

end
