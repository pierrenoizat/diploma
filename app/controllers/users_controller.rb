class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :correct_user?, :except => [:index, :destroy, :edit]
  before_action :current_user_admin?, :except => [:show, :edit, :update, :show_authorized]
  
  require 'money-tree'

  include Bitcoin::Builder

  def index
    @users = User.all
    
    @users.each do |user|
      if user.issuer_id.blank?
        @issuer = Issuer.create(:category => :individual, :name => user.email, :mpk => Rails.application.secrets.mpk)
        user.issuer_id = @issuer.id
        user.save
      end
    end
    
  end
  
  def dashboard
    @user = User.find(params[:id])
    @users = User.all
  end
  
  def create
    @user = User.new(user_params)
    
    @users = User.all
    exist = false
    @users.each do |user|
     if user.email == @user.email
       exist = true
     end
    end
    
    if exist
      @user = User.find_by_email(params[:user][:email])
      @user.update(user_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      redirect_to root_url, notice: 'User not registered yet.'
    end
    
  end

  def show
    @user = User.find(params[:id])
    
    @user.deeds.each do |deed|
      if (deed.issuer_id.blank? and Issuer.find_by_name(@user.email))
        deed.issuer_id = Issuer.find_by_name(@user.email).id
        deed.save
      end
    end

    @deeds = @user.deeds
    @deeds = @deeds.paginate(:page => params[:page], :per_page => 2)
  end
  
  def show_authorized
    @user = User.find(params[:id])

    @viewers = Viewer.where(:email => @user.email)
    @deeds = []
    @viewers.each do |viewer|
      @deed = Deed.find_by_id(viewer.deed_id)
      @deeds << @deed
    end

  end
  
  # GET /deeds/1/edit
  def edit
      @user = User.find(params[:id])
      @issuer = Issuer.find_by_id(@user.issuer_id)
      @issuers = Issuer.where(:category => :school)
  end
  
  def update
    respond_to do |format|
      if @user.update(user_params)
        format.html { redirect_to @user, notice: 'User was successfully updated.' }
        format.json { render :show, status: :ok, location: @user }
      else
        format.html { render :edit }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    if current_user.uid == $ADMIN_UID
      @user = User.find(params[:id])
      @user.deeds.each do |deed|
        deed.avatar = nil
        deed.save # destroy attachment first
        deed.delete
      end
    
      @user.delete
      # @users = User.all
      respond_to do |format|
        format.html { redirect_to users_path, notice: 'User was successfully destroyed.' }
        format.json { head :no_content }
      end
    else
      redirect_to users_path, notice: 'Access denied for delete action.'
    end
  end
  
  
  def fund_utxos # fund multiple utxos that will be used in op return transactions, preventing unconfirmed/unspent conflicts

    @user = User.find(params[:id])
    @issuer = Issuer.find_by_id(@user.issuer_id)
    @users = User.all
    string = $BLOCKR_ADDRESS_UNSPENT_URL + $PAYMENT_ADDRESS # ?multisigs=1
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
         @address_balance += result['data']['unspent'][k]['amount'].to_f
         prev_out_index[k] = result['data']['unspent'][k]['n'].to_i
         string = $WEBBTC_TX_URL + "#{tx_id }.json" # $WEBBTC_TX_URL = "http://webbtc.com/tx/"
         @agent = Mechanize.new

         begin
           page = @agent.get string
         rescue Exception => e
           string = "https://bitcoin.toshi.io/api/v0/transactions/" + tx_id #  if webbtc.com is unavailable
           page = @agent.get string
         end

         data = page.body
         # TODO handle errors if webbtc server is down
         prev_tx[k] = Bitcoin::P::Tx.from_json(data)

         # use those utxos as inputs

         t.input do |i|
           i.prev_out prev_tx[k]
           i.prev_out_index prev_out_index[k]
           # i.signature_key key
         end

       end # for loop

       @new_balance = @address_balance*100000000 - $NETWORK_FEE # in satoshis
       @utxo_amount = @new_balance/$PAYMENT_NODES_COUNT
       
       for k in 1..$PAYMENT_NODES_COUNT
         # TODO handle issuer specific mpk
         @master = MoneyTree::Master.from_bip32(@issuer.mpk)
         @recipient_node = @master.node_for_path "M/2/#{k}" # using a capital "M" instead of a lowercase "m", we will receive a node that is stripped of its private key.

         t.output do |o|
           o.value @utxo_amount # in satoshis
           o.script {|s| s.recipient @recipient_node.to_address }
         end
         
       end

       @send_notification = ( @address_balance < 100*$NETWORK_FEE )

     end # build_tx

     @master = MoneyTree::Master.from_bip32(Rails.application.secrets.msk) # TODO handle issuer specific msk
     @payment_node = @master.node_for_path $PAYMENT_ADDRESS_PATH

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
         @tx_hash = post_response["tx"]["hash"] # save tx id from blockcypher api response rather than tx id computed by the app.
       end
     
       puts @tx_id
       puts @tx_hash
     end

    
  end
  
  def refund_payment_address
    # when collection address balance > $OP_RETURN_AMOUNT*$PAYMENT_NODES_COUNT*0.9
    @users = User.all
    render :index
  end
  
  private
  
  def user_params
    params.require(:user).permit(:issuer_id, :email, :category, :credit, deeds_attributes: [:user_id, :name, :upload, :category, :tx_hash, :tx_id])
  end

end
