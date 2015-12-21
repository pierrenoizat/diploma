class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?
  helper_method :setup
  helper_method :insert_file
  
  
  API_VERSION = 'v2'
  CACHED_API_FILE = "drive-#{API_VERSION}.cache"
  CREDENTIAL_STORE_FILE = "#{$0}-oauth2.json"

  # Handles authentication and loading of the API.
  def setup
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
  def insert_file(client, drive)
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

    def correct_user?
      @user = User.find(params[:id])
      unless current_user == @user
        redirect_to root_url, :alert => "Access denied."
      end
    end

    def authenticate_user!
      if !current_user
        redirect_to root_url, :alert => 'You need to sign in for access to this page.'
      end
    end

end
