class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :user_signed_in?, :current_user_admin?
  helper_method :correct_user?, :utxo_addresses, :balance
  helper_method :setup
  helper_method :insert_file
  
  
  API_VERSION = 'v2'
  CACHED_API_FILE = "drive-#{API_VERSION}.cache"
  CREDENTIAL_STORE_FILE = "#{$0}-oauth2.json"
  
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
    complete = false
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

  # Handles authentication and loading of the API.
  def setup # unused method
    log_file = File.open('drive.log', 'a+')
    log_file.sync = true
    logger = Logger.new(log_file)
    logger.level = Logger::DEBUG

    client = Google::APIClient.new(:application_name => 'Ruby Drive sample',
        :application_version => '1.0.0')

    # FileStorage stores auth credentials in a file, so they survive multiple runs
    # of the application. This avoids prompting the user for authorization every
    # time the access token expires, by remembering the refresh token.
    # Note: FileStorage is not suitable for multi-user applications.
    file_storage = Google::APIClient::FileStorage.new(CREDENTIAL_STORE_FILE)
    if file_storage.authorization.nil?
      client_secrets = Google::APIClient::ClientSecrets.load
      # The InstalledAppFlow is a helper class to handle the OAuth 2.0 installed
      # application flow, which ties in with FileStorage to store credentials
      # between runs.
      flow = Google::APIClient::InstalledAppFlow.new(
        :client_id => "13643323269-3rkf77uiu6alpqh4jd2oqk44t45d07a2.apps.googleusercontent.com",
        :client_secret => "YnJnaWmibUSzmu5YGCoLhGFu",
        :scope => ['https://www.googleapis.com/auth/drive']
      )
      client.authorization = flow.authorize(file_storage)
    else
      client.authorization = file_storage.authorization
    end

    drive = nil
    # Load cached discovered API, if it exists. This prevents retrieving the
    # discovery document on every run, saving a round-trip to API servers.
    if File.exists? CACHED_API_FILE
      File.open(CACHED_API_FILE) do |file|
        drive = Marshal.load(file)
      end
    else
      drive = client.discovered_api('drive', API_VERSION)
      File.open(CACHED_API_FILE, 'w') do |file|
        Marshal.dump(drive, file)
      end
    end

    return client, drive
  end

  # Handles files.insert call to Drive API.
  def insert_file(client, drive)  # unused method
    # Insert a file
    file = drive.files.insert.request_schema.new({
      'title' => 'My document',
      'description' => 'A test document',
      'mimeType' => 'image/jpg'
    })

    media = Google::APIClient::UploadIO.new(Rails.root.join('IMG.jpg'), 'image/jpg')
    
    result = client.execute(
      :api_method => drive.files.insert,
      :body_object => file,
      :media => media,
      :parameters => {
        'uploadType' => 'multipart',
        'alt' => 'json'})

    # Pretty print the API result
    jj result.data.to_hash
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
        unless (current_user.uid == $ADMIN_UID)
          redirect_to root_url, :alert => 'You need to sign in as admin for access to this page.'
        end
    end

    def correct_user?
      @user = User.find_by_id(params[:id])
      unless ((current_user == @user) or (current_user.uid == $ADMIN_UID))
        redirect_to root_url, :alert => "Access denied."
      end
    end

    def authenticate_user!
      if !current_user
        redirect_to root_url, :alert => 'You need to sign in for access to this page.'
      end
    end

end
