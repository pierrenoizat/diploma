class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :user_signed_in?, :current_user_admin?
  helper_method :correct_user?, :utxo_addresses, :balance
  helper_method :setup
  helper_method :insert_file
  
  
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
  
  def utxo_addresses
    # returns an array of unspent addresses available to fund OP_RETURN transactions
    @addresses =[]

    @master = MoneyTree::Master.from_bip32(Rails.application.secrets.msk)
    i = 1
    while (i <= $PAYMENT_NODES_COUNT)
     
      payment_node = @master.node_for_path "m/2/#{i}"

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
