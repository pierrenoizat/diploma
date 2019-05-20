Rails.application.routes.draw do
  
  resources :viewers do
    member do
      get 'verify'
    end
    end
    
  resources :issuers do
    resources :batches
    resources :users
    collection do
      get 'school_list'
    end
    member do
      get 'batch_list'
    end
    end
    
  resources :deeds do
    resources :viewers
    member do
      get 'download'
      get 'download_report'
      get 'download_sample'
      get 'log_hash'
      get 'display_tx'
      get 'verify'
      get 'public_display'
    end
    end
  
  resources :users do
      member do
        get 'fund_utxos'
        get'refund_payment_address'
        get 'dashboard'
        get 'show_authorized'
        get 'show_profile'
      end
    end
    
  resources :batches do
    member do
      get 'prepare_tx'
      post 'generate_pdf'
      get 'search'
      post 'search'
    end
  end
  
  resources :batches do
    resources :deeds
    member do
       post 'download_pdf'
     end
  end
  
  match '/contacts',     to: 'contacts#new',             via: 'get'
  match '/contacts',     to: 'contacts#create',          via: 'post'
  resources "contacts", only: [:new, :create]
  
  root to: 'visitors#index'
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'
  
  # error pages
   %w( 404 422 500 503 ).each do |code|
     get code, :to => "errors#show", :code => code
   end
  
end
