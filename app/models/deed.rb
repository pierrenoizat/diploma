class DeedValidator < ActiveModel::Validator
  
  def validate(record)
    
    authorized_issuers = case record.issuer
  	  when 'ESILV' then ['boussac.75011@gmail.com']
  	  when 'TEST SCHOOL' then ['pierre.noizat@paymium.com']
  	  else User.select("email").to_a
  	end
    
   unless authorized_issuers.include?(User.find_by_id(record.user_id).email)
     record.errors[:base] << "You are not authorized by #{record.issuer}."
   end
    
  end # of validate method
  
end


class Deed < ActiveRecord::Base
  enum category: [:diploma, :identity, :property, :book, :paper, :audio, :video]
  belongs_to :user
  # belongs_to :issuer
  has_many :viewers
  
  ISSUERS = ["TEST SCHOOL", "ESILV", "Unregistered School or University"]
  
    attr_readonly :user_id

    
    has_attached_file :avatar,
     :default_url => "/images/:style/missing.png",
     :storage => :s3,
     :s3_permissions => :public_read,
     :s3_credentials => "#{Rails.root}/config/aws.yml",
     :bucket => 'hashtree-assets',
     :s3_host_name => 's3-eu-west-1.amazonaws.com',
     :path => ":filename",
     :s3_storage_class => :standard
     # :s3_options => { :server => "s3-eu-west-1.amazonaws.com" }

     validates_attachment :avatar,
       :size => { :in => 0..$MAX_SIZE.kilobytes }

     # validates_attachment_content_type :avatar, :content_type => /\Aimage\/.*\Z/

     validates_attachment :avatar,
       :content_type => { :content_type => ["image/jpeg", "image/png", "application/pdf"] }

     validates_attachment_file_name :avatar, :matches => [/png\Z/, /jpe?g\Z/,/pdf\Z/,/JPE?G\Z/,/PNG\Z/,/PDF\Z/]
     # Explicitly do not validate
     do_not_validate_attachment_file_type :avatar
     
     validates_with DeedValidator

     require 'money-tree'

     include Bitcoin::Builder
     
     def broadcast_tx
       
       unless self.tx_raw.blank?
         puts self.tx_raw
         # $PUSH_TX_URL = "https://api.blockcypher.com/v1/btc/main/txs/push"
         uri = URI.parse($PUSH_TX_URL)  # param is "tx"

         http = Net::HTTP.new(uri.host, uri.port)
         http.use_ssl = true

         request = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json'})
         if ($BROADCAST == true)
           data = {"tx": self.tx_raw}
           request.body = data.to_json

           response = http.request(request)  # broadcast transaction using $PUSH_TX_URL
           post_response = JSON.parse(response.body)
        
           puts post_response
           if post_response["error"]
             @tx_id = "Due to malleability issue, Tx ID is not confirmed yet. Broadcast tx again later: #{@raw_transaction}"
           else
             @tx_id = "Confirmed Tx ID: #{post_response["tx"]["hash"]}"
             self.tx_hash = post_response["tx"]["hash"] # save tx id from blockcypher api response rather than tx id computed by the app.
             self.save
           end
         end # if $BROADCAST 
      end
      
     end # of broadcast_tx method

     def op_return_tx
       
       complete = false
       @master = MoneyTree::Master.from_bip32(Rails.application.secrets.msk)
       i = 1
       while ((i <= $PAYMENT_NODES_COUNT) and (complete == false))
         
         @payment_node = @master.node_for_path "m/2/#{i}"
  
         @payment_address = @payment_node.to_address
         string = $BLOCKR_ADDRESS_BALANCE_URL + @payment_address + "?confirmations=0"

         @agent = Mechanize.new

       begin
         page = @agent.get string
       rescue Exception => e
         page = e.page
       end

       data = page.body
       result = JSON.parse(data)
       # complete = (page.body[:data][:balance].to_f > ($NETWORK_FEE/100000000))
       complete = (result['data']['balance'].to_f > ($NETWORK_FEE/100000000))
       i += 1
     end # while
     
     puts "Payment address: #{@payment_address}"
     # puts "Payment address balance: #{balance(@payment_address)} BTC"
     puts i-1
         
     string = $BLOCKR_ADDRESS_UNSPENT_URL  + @payment_address
     tx_id = ""
     prev_out_index = []
     prev_tx = []
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
     n = result['data']['unspent'].count - 1

    new_tx = build_tx do |t|
      for k in 0..n

        tx_id = result['data']['unspent'][k]['tx'] # fetch the tx ID of the i+1 unspent output available from address
           
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

        prev_tx[k] = Bitcoin::P::Tx.from_json(data)
        @address_balance += result['data']['unspent'][k]['amount'].to_f
        prev_out_index[k] = result['data']['unspent'][k]['n'].to_i
           # use those utxos as inputs
           
        t.input do |i|
          i.prev_out prev_tx[k]
          i.prev_out_index prev_out_index[k]
          # i.signature_key key
        end

      end # for loop

         @new_balance = @address_balance*100000000 - $NETWORK_FEE # in satoshis

         t.output do |o|
           o.value @new_balance
           o.script {|s| s.recipient $COLLECTION_ADDRESS }
         end

         t.output do |o|
             # specify the deed hash to encode in the blockchain    
             o.to self.upload.unpack("H*"), :op_return
             # specify the value of this output (zero)
             o.value 0
           end

         @send_notification = ( @address_balance < 100*$NETWORK_FEE )
       end # build_tx

       # @master = MoneyTree::Master.from_bip32(Rails.application.secrets.msk)
       # @payment_node = @master.node_for_path $PAYMENT_ADDRESS_PATH

       payment_private_key = @payment_node.private_key.to_hex
       payment_private_key = Bitcoin::Key.new(payment_private_key).to_base58

       @payment_keypair = Bitcoin::Key.from_base58(payment_private_key)
       payment_key = Bitcoin.open_key Bitcoin::Key.from_base58(payment_private_key).priv # private key corresponding to payment address (standard address only, TODO: handle multisigs)

       for k in 0..n
           signature = Bitcoin.sign_data(payment_key, new_tx.signature_hash_for_input(k, prev_tx[k])) # sign first input in new tx
           new_tx.in[k].script_sig = Bitcoin::Script.to_pubkey_script_sig(signature, @payment_keypair.pub.htb) # add signature and public key to first input in new tx
       end

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
           self.tx_hash = post_response["tx"]["hash"] # save tx id from blockcypher api response rather than tx id computed by the app.
         end
       
         puts @tx_id
       end # if $BROADCAST
       self.tx_raw = @raw_transaction
       self.save
       @raw_transaction

     end # of op_return_tx method
     
     def confirmation_email
       user = User.find_by_id(self.user_id)
       client = SendGrid::Client.new(api_key: Rails.application.secrets.sendgrid_api_key)
       
       mail = SendGrid::Mail.new do |m|
         m.to = user.email
         m.from = 'diploma.report'
         m.subject = 'Deed upload confirmation'
         m.text = "Your deed, #{self.name}, was uploaded successsfully to diploma.report ."
       end

       res = client.send(mail)
       puts res.code
       puts res.body
     end 
     
     
     def signed_email(to_email)
             msk = case self.issuer
          	    when 'ESILV' then Rails.application.secrets.msk_esilv
          	    when 'TEST SCHOOL' then Rails.application.secrets.msk
          	    else Rails.application.secrets.msk
          	  end

          	  complete = false
              @master = MoneyTree::Master.from_bip32(msk)
              i = 1
              while ((i <= $PAYMENT_NODES_COUNT) and (complete == false))

                @payment_node = @master.node_for_path "m/2/#{i}"

                @payment_address = @payment_node.to_address
                string = $BLOCKR_TX_URL + self.tx_hash

                @agent = Mechanize.new

                begin
                  page = @agent.get string
                rescue Exception => e
                  page = e.page
                end

                data = page.body
                result = JSON.parse(data)

                complete = (result['data']['trade']['vins'][0]['address'] == @payment_address )
                i += 1
                puts i.to_s
                puts result['data']['trade']['vins'][0]['address']
                puts complete
              end # while
              puts @payment_address
              
              text = "Your deed, #{self.name}, was verified successfully by diploma.report. This message is signed by its issuer: #{self.issuer}."
              key1 = Bitcoin::Key.new(@payment_node.private_key.to_hex) # priv key in hex
              signature = key1.sign_message(text)
              text = text + "\n Address: " + @payment_address + "\n " + "\n Signature: " + signature 
              user = User.find_by_id(self.user_id)
              # @current_user ||= User.find(session[:user_id]) if session[:user_id]
              client = SendGrid::Client.new(api_key: Rails.application.secrets.sendgrid_api_key)


              mail = SendGrid::Mail.new do |m|
                m.to = to_email
                m.cc = user.email
                m.from = 'diploma.report'
                m.subject = 'Signed verification message'
                m.text = text
              end

              res = client.send(mail)
              puts res.code
              puts res.body
           end
     

  end
