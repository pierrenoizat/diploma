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
    Deed.all.each do |deed|
      if deed.description == self.payment_address
        return deed.tx_hash
      end
    end
  end
  
  
  def root_file_hash
    # batch root pdf file is a list showing the hashes of all the diplomas
    # root_file_hash is the hash of this batch root pdf file
    # root pdf file is manually uploaded as a batch deed with the batch Bitcoin address (payment_address) as description.
    Deed.all.each do |deed|
      if deed.description == self.payment_address
        return deed.upload
      end
    end
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

        @output_amount = @input_amount*100000000 - 10000 # in satoshis, fee is around 5 cts as of june 2016

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

    string = $BLOCKR_ADDRESS_UNSPENT_URL  + @payment_address
    tx_id = ""
    prev_out_index = 0
    prev_tx = nil

    @agent = Mechanize.new
    
    begin
      page = @agent.get string
    rescue Exception => e
      page = e.page
    end

    data = page.body
    result = JSON.parse(data)
    n = result['data']['unspent'].count

    if n < 1
      text = "Not enough utxos for #{self.issuer.name}, #{self.batch.title}."
      puts text
      return nil
    else

    new_tx = build_tx do |t|

       tx_id = result['data']['unspent'][0]['tx'] # fetch the tx ID of the first unspent output available from address
       
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
       @input_amount = result['data']['unspent'][0]['amount'].to_f
       prev_out_index = result['data']['unspent'][0]['n'].to_i
       # use that utxo as input
       ################################################
       t.input do |i|
         i.prev_out prev_tx
         i.prev_out_index prev_out_index
         # i.signature_key key
       end

        @output_amount = @input_amount*100000000 - $NETWORK_FEE # in satoshis

        t.output do |o|
          o.value @output_amount
          o.script {|s| s.recipient $COLLECTION_ADDRESS }
        end
        
        t.output do |o|
            # specify the deed hash to encode in the blockchain    
            o.to self.root_hash.unpack("H*"), :op_return
            # specify the value of this output (zero)
            o.value 0
        end
        
        
        # self.deeds.each do |deed|
        #  t.output do |o|
            # specify the deed hash to encode in the blockchain    
        #    o.to deed.upload.unpack("H*"), :op_return
            # specify the value of this output (zero)
       #     o.value 0
       #   end
       # end
      #################################################

      end # build_tx
      
      puts "Root Hash: "+ self.root_hash

      @payment_keypair = Bitcoin::Key.from_base58(self.payment_private_key)
      payment_key = Bitcoin.open_key Bitcoin::Key.from_base58(self.payment_private_key).priv # private key corresponding to payment address (standard address only, TODO: handle multisigs)

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
     
   end # of batch_authentification_tx method
  
end
