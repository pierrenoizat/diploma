class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :user_signed_in?, :current_user_admin?
  helper_method :correct_user?, :utxo_addresses, :balance, :unspent_address_utxo_count
  # helper_method :setup
  # helper_method :insert_file
  
  include Bitcoin::Builder
  
  def balance(address)
    string = $BLOCKR_ADDRESS_BALANCE_URL + address + "?confirmations=0"
    @agent = Mechanize.new
    begin
      page = @agent.get string
    rescue Exception => e
      page = e.page
    end
    data = page.body
    result = JSON.parse(data)
    return result['data']['balance'].to_f
  end
  
  def unspent_address_utxo_count(address)
  
    # returns count ( < $STUDENTS_COUNT) of utxos available to fund OP_RETURN transactions from single address (school class diplomas).
    # TODO publish this address next to school name and class (year)
    string = $BLOCKR_ADDRESS_UNSPENT_URL  + address
    puts string
    @agent = Mechanize.new

     begin
       page = @agent.get string
     rescue Exception => e
       page = e.page
     end

     data = page.body
     result = JSON.parse(data)
     
     if result['data']['unspent']
       return result['data']['unspent'].count
     else
       return 0
     end
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
      string = $BLOCKR_ADDRESS_BALANCE_URL + payment_address + "?confirmations=0"

      @agent = Mechanize.new

      begin
        page = @agent.get string
      rescue Exception => e
        page = e.page
      end

      data = page.body
      result = JSON.parse(data)
      if (result['data']['balance'].to_f > ($NETWORK_FEE/100000000))
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
