class Batch < ActiveRecord::Base
  belongs_to :issuer
  has_many :deeds
  require 'money-tree'
  include Bitcoin::Builder
  
  def payment_address
    @master = MoneyTree::Master.from_bip32(self.issuer.mpk)
    @payment_node = @master.node_for_path "M/4/#{self.id}" # capital M for"public-key only" node, we could be using m for full "secret-key" node
    @payment_node.to_address # publish this address next to school name and class (year)
  end
  
  def payment_private_key
    @master = MoneyTree::Master.from_bip32(self.issuer.msk)
    @payment_node = @master.node_for_path "m/4/#{self.id}"
    payment_private_key = @payment_node.private_key.to_hex
    payment_private_key = Bitcoin::Key.new(payment_private_key).to_base58
  end
  
  def tx_hash
    string = ""
    if self.tx_raw
      string = BTC::Transaction.new(hex: self.tx_raw).transaction_id
    end
    string
  end
  
  
  def root_file_hash
    # batch root pdf file is a list showing the hashes of all the diplomas
    # root_file_hash is the hash of this batch root pdf file
    # root pdf file is manually uploaded as a batch deed with the batch Bitcoin address (payment_address) as description.
    hash = nil
    Deed.all.each do |deed|
      if deed.description == self.payment_address  # caracterize a batch root file
        hash = deed.upload  # deed.upload is the hash of the deed file
      end
    end
    hash
  end
  
  def broadcast_tx
    
    # $PUSH_TX_URL = "https://api.blockcypher.com/v1/btc/main/txs/push"
    uri = URI.parse($PUSH_TX_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json'})
      
    data = {"tx": self.tx_raw}
    request.body = data.to_json
    response = http.request(request)  # broadcast transaction using $PUSH_TX_URL
    post_response = JSON.parse(response.body)
    puts post_response
    if post_response["error"]
      @tx_id = "Due to malleability issue, Tx ID is not confirmed yet. Broadcast tx again later: #{self.tx_raw}"
    else
      @tx_id = "Confirmed Tx ID: #{post_response["tx"]["hash"]}"
      Deed.all.each do |deed|
        if deed.description == self.payment_address
          deed.tx_hash = post_response["tx"]["hash"]
          deed.save
        end
      end
    end
    puts @tx_id

    self.tx_raw
  end
  
  def batch_init_tx
    # DEPRECATED: simply fund self.payment_address with admin wallet (any wallet)
    # fund batch.payment_address from 
    @payment_address = self.payment_address
    puts "Init payment address: #{$PAYMENT_ADDRESS}"

    string = $BLOCKR_ADDRESS_UNSPENT_URL  + $PAYMENT_ADDRESS
    tx_id = ""
    prev_out_index = 0
    prev_tx = nil
    
    @agent = Mechanize.new
    
    begin
      blockr = true
      page = @agent.get string
    rescue Exception => e
      blockr = false
      string = "https://bitcoin.toshi.io/api/v0/addresses/"+ $PAYMENT_ADDRESS + "/unspent_outputs" #  if blockr.io is unavailable
      page = @agent.get string
    end
    
    if blockr
      data = page.body
      result = JSON.parse(data)
      n = result['data']['unspent'].count
      tx_id = result['data']['unspent'][0]['tx'] # fetch the tx ID of the first unspent output available from address
      prev_out_index = result['data']['unspent'][0]['n'].to_i
      @input_amount = result['data']['unspent'][0]['amount'].to_f
    else # toshi
      data = page.body
      result = JSON.parse(data)
      n = result.count
      tx_id = result[0]['transaction_hash'] # fetch the tx ID of the first unspent output available from address
      prev_out_index = result[0]['output_index'].to_i
      @input_amount = result[0]['amount'].to_i
    end

    

    if n < 1
      text = "Not enough utxos for #{self.issuer.name}, #{self.batch.title}."
      puts text
      return nil
    else

    new_tx = build_tx do |t|

       
       
       string = $WEBBTC_TX_URL + "#{tx_id }.json" # $WEBBTC_TX_URL = "http://webbtc.com/tx/"
       @agent = Mechanize.new

       begin
         blockr = false
         page = @agent.get string
       rescue Exception => e
         blockr = true
         string = "http://btc.blockr.io/api/v1/tx/raw/" + tx_id #  if webbtc.com is unavailable
         page = @agent.get string
       end

       data = page.body
       # TODO check that utxo is not already spent
       if blockr
         result = JSON.parse(data)
         raw_tx = result['data']['tx']['hex']
         prev_tx = Bitcoin::Protocol::Tx.new(raw_tx.htb)
       else 
         prev_tx = Bitcoin::P::Tx.from_json(data)
       end
       # use that utxo as input
       ################################################
       t.input do |i|
         i.prev_out prev_tx
         i.prev_out_index prev_out_index
         # i.signature_key key
       end

        @output_amount = @input_amount*100000000 - 100000 # in satoshis

        t.output do |o|
          o.value @output_amount
          o.script {|s| s.recipient @payment_address }
        end
        
      #################################################

      end # build_tx
      @master = MoneyTree::Master.from_bip32(Rails.application.secrets.msk)
      @payment_node = @master.node_for_path "m/1/3"
      # $PAYMENT_ADDRESS = @payment_node.to_address
      payment_private_key = @payment_node.private_key.to_hex
      payment_private_key = Bitcoin::Key.new(payment_private_key).to_base58
      @payment_keypair = Bitcoin::Key.from_base58(payment_private_key)
      payment_key = Bitcoin.open_key Bitcoin::Key.from_base58(payment_private_key).priv # private key corresponding to payment address (standard address only, TODO: handle multisigs)

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
      
      self.tx_raw = @raw_transaction
      self.save

      if ($BROADCAST == true)
        self.broadcast_tx
      end # if $BROADCAST

      @raw_transaction
    end
     
   end # of batch_init_tx method
  
  def batch_authentification_tx
     
    # single OP_RETURN tx signed by a school's private key for multiple diplomas
    # please note that the protocol does NOT currently accept multi-op-return tx
    # the root hash is computed simply by concatenation of all the diploma hashes.
    # therefore the proof must include the diploma hash list
    
    @payment_address = self.payment_address
    puts "Payment address: #{@payment_address}"

    tx_id = ""
    prev_out_index = 0
    prev_tx = nil
    utxo = Hash.new
    utxo = utxo(@payment_address)
    # n = result['data']['unspent'].count

    if utxo['tx_hash'].blank?
      text = "Not enough utxos for #{self.issuer.name}, #{self.title}."
      puts text
      return nil
    else

       @previous_id = utxo['tx_hash'] # fetch the tx ID of the first unspent output available from address
       @input_amount = utxo['amount'].to_f
       @previous_index = utxo['index'].to_i
       
       ##########################
       
       @batch_key = BTC::Key.new(wif:self.payment_private_key)
       @batch_address = self.payment_address
       # @value = (self.amount.to_f * BTC::COIN).to_i - $NETWORK_FEE # in satoshis, amount MUST be 200 000 satoshis (~ 2 €)
       @value = @input_amount.to_i - $NETWORK_FEE
       BTC::Network.default = BTC::Network.mainnet
       @op_return_script = BTC::Script.new(op_return: self.deeds.last.upload)

       tx = BTC::Transaction.new
       tx.lock_time = 1471199999 # some time in the past (2016-08-14)
       tx.add_input(BTC::TransactionInput.new( previous_id: @previous_id, # UTXO has been funded by Alice
                                               previous_index: @previous_index,
                                               sequence: 0))
       tx.add_output(BTC::TransactionOutput.new(value: @value, 
                                               script: BTC::Address.parse($COLLECTION_ADDRESS).script))
       tx.add_output(BTC::TransactionOutput.new(value: 0, script: @op_return_script))
       hashtype = BTC::SIGHASH_ALL
       sighash = tx.signature_hash(input_index: 0,
                                   output_script: BTC::PublicKeyAddress.new(string:@batch_address).script,
                                   hash_type: hashtype)
       tx.inputs[0].signature_script = BTC::Script.new    
       @batch_key = BTC::Key.new(wif:self.payment_private_key)   
       tx.inputs[0].signature_script << (@batch_key.ecdsa_signature(sighash) + BTC::WireFormat.encode_uint8(hashtype))
       tx.inputs[0].signature_script << @batch_key.compressed_public_key
       return tx.to_s
      
      puts "Root Hash: "+ self.root_hash

      @raw_transaction = tx.to_s # 166-character hex string, signed raw transaction
      @json_tx = JSON.parse(tx.to_json)

      # print hex version of new signed transaction
      puts "Hex Encoded Transaction:\n\n"
      puts @raw_transaction
      puts "\n\n"
      # print JSON version of new signed transaction
      puts "Tx ID: "+ @json_tx["hash"]
      self.tx_raw = @raw_transaction
      self.save
      if ($BROADCAST == true)
        self.broadcast_tx
      end # if $BROADCAST
      
      @raw_transaction
    end
     
   end # of batch_authentification_tx method
   
   
   def utxo(address)
     utxo_params = Hash.new

     string = $BLOCKCHAIN_UTXO_URL + address.to_s
     @agent = Mechanize.new
     begin
     page = @agent.get string
     rescue Exception => e
     page = e.page
     end

     data = page.body
     result = JSON.parse(data)
     if !result['unspent_outputs'].blank?
       result['unspent_outputs'].each do |utx|
         if utx['value'].to_f >= 5000
           utxo_params["tx_hash"] = utx["tx_hash_big_endian"]
           utxo_params["index"] = utx["tx_output_n"].to_i
           utxo_params["amount"] = utx["value"].to_f  # amount in satoshis
           utxo_params["confirmations"] = utx["confirmations"].to_i
         end
       end
     else
       puts "No utxo avalaible for #{address}"
     end
     utxo_params
   end # of model method utxo
  
end
