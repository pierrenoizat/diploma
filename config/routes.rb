Rails.application.routes.draw do
  
  resources :issuers
  resources :viewers do
    member do
      get 'verify'
    end
    end
    
  resources :deeds do
    resources :viewers
    member do
      get 'download'
      get 'download_sample'
      get 'log_hash'
      get 'verify'
    end
    end
  
  resources :users do
      member do
        get 'fund_utxos'
        get'refund_payment_address'
        get 'dashboard'
        get 'show_authorized'
      end
    end
  
  root to: 'visitors#index'
  get '/auth/:provider/callback' => 'sessions#create'
  get '/signin' => 'sessions#new', :as => :signin
  get '/signout' => 'sessions#destroy', :as => :signout
  get '/auth/failure' => 'sessions#failure'
end
