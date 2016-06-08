class Issuer < ActiveRecord::Base
  enum category: [:school, :individual]
  has_many :deeds
  has_many :users
  SCHOOLS = ["TEST SCHOOL", "ESILV", "CDI", "TEST"]
  # validates :name, :inclusion => SCHOOLS # not anymore, since email address is a user default issuer name
  
  validates :mpk, presence: true
  validates :name, presence: true
  validates :name, uniqueness: true
  
  include Bitcoin::Builder
  
  def msk
    
    # pick issuer-specific (school) msk
     msk = case self.name
     when "ESILV 2014"
      Rails.application.secrets.msk_esilv
     when "TEST SCHOOL"
      Rails.application.secrets.msk_esilv
     when "TEST"
      Rails.application.secrets.msk_esilv
     when "CDI"
      Rails.application.secrets.msk_esilv
     else
      Rails.application.secrets.msk
     end
    
  end
  
  def address_matching_signature
    
    @master = MoneyTree::Master.from_bip32(self.mpk)
    @payment_node = @master.node_for_path "M/3/#{self.id}" # capital M for"public-key only" node, we could be using m for full "secret-key" node
    @payment_node.to_address
    
  end
  
  
  def init_funding_tx
     # init transaction funding School's address (for a given year)
     # @issuer = Issuer.find_by_id(self.id)
     enough_funds = false
     @master = MoneyTree::Master.from_bip32(self.msk)
     @payment_node = @master.node_for_path "M/3/#{self.id}" # capital M for"public-key only" node, we could be using m for full "secret-key" node
     @payment_address = @payment_node.to_address # TODO publish this address next to school name and class (year)
     
     string = $BLOCKR_ADDRESS_BALANCE_URL + $PAYMENT_ADDRESS + "?confirmations=0"
     
     @agent = Mechanize.new

     begin
       page = @agent.get string
     rescue Exception => e
       page = e.page
     end

     data = page.body
     result = JSON.parse(data)
     # check that $PAYMENT_ADDRESS holds sufficient balance
     enough_funds = (result['data']['balance'].to_f > (($NETWORK_FEE/100000000))*$STUDENTS_COUNT)
     
     string = $BLOCKR_ADDRESS_UNSPENT_URL  + $PAYMENT_ADDRESS
     puts string
     puts @payment_address
       
     tx_id = ""
     prev_out_index = 0
     prev_tx = nil
     @address_balance = 0
     @send_notification = false
     total_rewards = 0

     @agent = Mechanize.new

     begin
       page = @agent.get string
     rescue Exception => e
       page = e.page
     end

     data = page.body
     result = JSON.parse(data)
     
     if result['data']['unspent'][0]
       
     tx_id = result['data']['unspent'][0]['tx'] # fetch the tx ID of the first unspent output available from address $PAYMENT_ADDRESS

     new_tx = build_tx do |t|

       string = $WEBBTC_TX_URL + "#{tx_id }.json" # $WEBBTC_TX_URL = "http://webbtc.com/tx/"
       @agent = Mechanize.new

       begin
         page = @agent.get string
       rescue Exception => e
         # page = e.page
         string = "https://bitcoin.toshi.io/api/v0/transactions/" + tx_id #  if webbtc.com is unavailable
         page = @agent.get string
       end

       data = page.body
       # TODO check that utxo is not already spent

       prev_tx = Bitcoin::P::Tx.from_json(data)
       @address_balance += result['data']['unspent'][0]['amount'].to_f
       prev_out_index = result['data']['unspent'][0]['n'].to_i
       # use this utxo as input

       t.input do |i|
         i.prev_out prev_tx
         i.prev_out_index prev_out_index
         # i.signature_key key
       end
       
       @amount = (@address_balance*100000000 - $NETWORK_FEE)/$STUDENTS_COUNT
       
       i = 1
        while i <= $STUDENTS_COUNT
          
          t.output do |o|
            o.value @amount # in satoshis
            o.script {|s| s.recipient @payment_address }
          end
          
          i +=1
        end  # while
         
      end  # build_tx

    # TODO review code below
    
    @master = MoneyTree::Master.from_bip32(Rails.application.secrets.msk)
    @payment_node = @master.node_for_path "m/1/3"  # node for $PAYMENT_ADDRESS
    payment_private_key = @payment_node.private_key.to_hex
    payment_private_key = Bitcoin::Key.new(payment_private_key).to_base58
    @payment_keypair = Bitcoin::Key.from_base58(payment_private_key)
    payment_key = Bitcoin.open_key Bitcoin::Key.from_base58(payment_private_key).priv # private key corresponding to $PAYMENT_ADDRESS

    signature = Bitcoin.sign_data(payment_key, new_tx.signature_hash_for_input(0, prev_tx)) # sign first input in new tx
    new_tx.in[0].script_sig = Bitcoin::Script.to_pubkey_script_sig(signature, @payment_keypair.pub.htb) # add signature and public key to first input in new tx

    @raw_transaction = new_tx.to_payload.unpack('H*')[0] # 166-character hex string, signed raw transaction
    @json_tx = JSON.parse(new_tx.to_json)

    # print hex version of new signed transaction
    puts "Hex Encoded Transaction:\n\n"
    puts @raw_transaction
    puts "\n\n"
    # print JSON version of new signed transaction
    puts "Tx ID: "+ @json_tx["hash"]
     
    # $PUSH_TX_URL = "https://api.blockcypher.com/v1/btc/main/txs/push"
    uri = URI.parse($PUSH_TX_URL)  # param is "tx"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json'})
    if ($BROADCAST == true)
      data = {"tx": @raw_transaction}
      request.body = data.to_json

      response = http.request(request)  # broadcast transaction using $PUSH_TX_URL
      post_response = JSON.parse(response.body)
     
      puts post_response
      if post_response["error"]
        @tx_id = "Due to malleability issue, Tx ID is not confirmed yet. Broadcast tx again later: #{@raw_transaction}"
      else
        @tx_id = "Confirmed Tx ID: #{post_response["tx"]["hash"]}"
      end
     
      puts @tx_id
    end # if $BROADCAST

    @raw_transaction
    
    else
      puts "#{$PAYMENT_ADDRESS} is not funded !"
      return nil # 
    end

   end # of init_funding_tx method
  
end
