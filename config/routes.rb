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
    end
  end
  
  resources :batches do
    resources :deeds
    member do
       post 'download_pdf'
     end
  end
  
  root to: 'visitors#index'
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'
end
