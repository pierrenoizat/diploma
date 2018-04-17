class Issuer < ActiveRecord::Base
  enum category: [:school, :individual]
  has_many :deeds
  has_many :users
  has_many :batches
  
  SCHOOLS = ["ESILV", "ESILV 2014", "ESILV 2015", "Test School", "Test ESSEC", "ESSEC", "ESILV 2016", "Test ESILV"]
  # validates :name, :inclusion => SCHOOLS # not anymore, since email address is a user default issuer name
  
  validates :mpk, presence: true
  validates :name, presence: true
  validates :name, uniqueness: true
  
  include Bitcoin::Builder
  
  def payment_address
    @master = MoneyTree::Master.from_bip32(self.mpk)
    @payment_node = @master.node_for_path "M/3/#{self.id}" # capital M for"public-key only" node, we could be using m for full "secret-key" node
    @payment_node.to_address # publish this address next to school name and class (year)
  end
  
  def payment_private_key
    @master = MoneyTree::Master.from_bip32(self.msk)
    @payment_node = @master.node_for_path "m/3/#{self.id}"
    payment_private_key = @payment_node.private_key.to_hex
    payment_private_key = Bitcoin::Key.new(payment_private_key).to_base58
  end
  
  def msk
    
    # pick issuer-specific (school) msk
     msk = case self.name
     when "ESILV 2014"
      Rails.application.secrets.msk_esilv
     when "ESILV"
        Rails.application.secrets.msk_esilv
     when "ESILV 2016", "Test ESILV"
      Rails.application.secrets.msk_esilv
     when "ESSEC"
      Rails.application.secrets.msk_essec
     else
      Rails.application.secrets.msk
     end
    
  end
  
  
  def init_funding_tx
    # TODO check that this method is NOT used, look for it in batch.rb instead
     # init transaction funding School's address (for a given year)
     # @issuer = Issuer.find_by_id(self.id)
     enough_funds = false
     @payment_address = self.payment_address
    
     # check that $PAYMENT_ADDRESS holds sufficient balance
     require "blockcypher"
     block_cypher = BlockCypher::Api.new(api_token: Figaro.env.blockcypher_api_token)
     enough_funds = (block_cypher.address_final_balance($PAYMENT_ADDRESS).to_f > (($NETWORK_FEE/100000000))*$STUDENTS_COUNT)
       
     tx_id = ""
     prev_out_index = 0
     prev_tx = nil
     @address_balance = 0
     @send_notification = false
     total_rewards = 0
     @address_details = block_cypher.address_details($PAYMENT_ADDRESS)
     if block_cypher.address_final_balance($PAYMENT_ADDRESS) > 0 # $PAYMENT_ADDRESS is funded
       count = @address_details["txrefs"].count
       i = 0
       j = 0
       while i < count
         unless @address_details["txrefs"][i]["spent"]
           j = i
         end
         i += 1
       end
       # fetch the tx ID of the first unspent output available from address $PAYMENT_ADDRESS
       i = 0
       @txs = block_cypher.address_full_txs($PAYMENT_ADDRESS)["txs"]
       while i < @txs.count
         j = 0
         while j < @txs[i]["outputs"].count
           if @txs[i]["outputs"][j]["addresses"][0] == $PAYMENT_ADDRESS
             unless @txs[i]["outputs"][j]["spent_by"]
               tx_id = @txs[i]["hash"]
               prev_out_index = j
               value = @txs[i]["outputs"][j]["value"].to_i
               script = @txs[i]["outputs"][j]["script"]
             end
           end
           j += 1
         end
         i += 1
       end
  
       puts tx_id
       puts prev_out_index
       puts value
       puts $PAYMENT_ADDRESS
       
     new_tx = build_tx do |t|
       # use this utxo as input
       
       t.input do |i|
               i.prev_out tx_id, prev_out_index, script.htb, value
             end
       
       @amount = (value - $NETWORK_FEE)/$STUDENTS_COUNT
       
       i = 1
        while i <= $STUDENTS_COUNT
          
          t.output do |o|
            o.value @amount # in satoshis
            o.script {|s| s.recipient @payment_address }
          end
          
          i +=1
        end  # while
         
      end  # build_tx
      
    # create the signed raw tx
    # first, sign the input, that is an utxo of $PAYMENT_ADDRESS
    @master = MoneyTree::Master.from_bip32(Rails.application.secrets.msk)
    @payment_node = @master.node_for_path "m/1/3"  # node for $PAYMENT_ADDRESS
    payment_private_key = @payment_node.private_key.to_hex
    payment_private_key = Bitcoin::Key.new(payment_private_key).to_base58
    @payment_keypair = Bitcoin::Key.from_base58(payment_private_key)
    payment_key = Bitcoin.open_key Bitcoin::Key.from_base58(payment_private_key).priv # private key corresponding to $PAYMENT_ADDRESS
    
    signature = Bitcoin.sign_data(payment_key, new_tx.in[0].sig_hash) # sign first input in new tx
    new_tx.in[0].script_sig = Bitcoin::Script.to_pubkey_script_sig(signature, @payment_keypair.pub.htb) # add signature and public key to first input in new tx

    @signed_raw_transaction = new_tx.to_payload.unpack('H*')[0] # 166-character hex string, signed raw transaction
    @json_tx = JSON.parse(new_tx.to_json)

    # print hex version of new signed transaction
    puts "Hex Encoded Transaction:\n\n"
    puts @signed_raw_transaction
    puts "\n\n"
    # print JSON version of new signed transaction
    puts "Tx ID: "+ @json_tx["hash"]
    
    # broadcast the signed raw tx if $BROADCAST is true
    if ($BROADCAST == true)
      broadcast(@signed_raw_transaction)
    else
      @signed_raw_transaction
    end # if $BROADCAST
    
    else
      puts "#{$PAYMENT_ADDRESS} is not funded !"
      return nil # 
    end

   end # of init_funding_tx method
  
end
