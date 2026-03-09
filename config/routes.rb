Rails.application.routes.draw do
  resources :jump_logs
  resources :ships do
    collection do
      get :new_modal
    end
  end
  resources :regions do
    member do
      get  :import_hexes
      post :upload_hexes
      get  :hex_template
    end
  end
  namespace :api do
    resources :sectors, only: :index
    resources :regions, only: :index
    resources :parsecs, only: :index
    get 'solarsystems', to: 'solar_systems#index'
    get 'solarsystem',  to: 'solar_system#show'
    resources :stars, only: %i[index update]
    get 'map', to: 'map#show'
  end

  resource :session
  resources :registrations
  resources :passwords, param: :token
  resources :tech_levels
  resources :governments
  resources :law_levels
  resources :facilities
  resources :trade_codes do
    collection do
      post 'import_t5'
    end
  end
  resources :stellar_objects

  resources :allegiances do
    collection do
      post 'import_from_traveller_map'
      get 'table'
      get 'search'
    end
  end

  resources :parsecs, only: %i[index show edit update] do
    resources :rogues, only: %i[new create index destroy]
    resources :star_systems, only: %i[new create index destroy]
    member do
      post :clear
      get :star_systems_table
    end
  end

  resources :star_systems do
    member do
      get :map
      get :select_main_world
      patch :set_main_world
      patch :update
      get :edit_bases
      post :update_bases
      get :edit_trade_codes
      post :update_trade_codes
    end
  end

  resources :stars, only: %i[index show edit update destroy] do
    collection do
      get :lookup
    end
  end

  resources :subsectors, only: %i[index show edit update] do
    member do
      post :clear
      get :populate, as: :populate
      post :generate, as: :generate
      get :star_systems_table
      post :load_defaults
      get :map
    end
    resources :rogues, only: %i[new create index destroy]
    resources :star_systems, only: %i[new create index destroy]
  end

  resources :sectors do
    collection do
      get :new_modal
      get :new_from_traveller_map
      get :new_from_default
    end
    member do
      post :clear
      get :populate, as: :populate
      post :generate, as: :generate
      post :load_defaults
      get :defaults_source
      get :map
    end
    resources :rogues, only: %i[index new create destroy]
    resources :star_systems, only: %i[new create index destroy]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get '/search', to: 'search#query'

  get '/settings', to: 'settings#index'

  get '/fairuse', to: 'marketing#fairuse'

  get '/help', to: 'help#index'
  get 'help/subsector_build_specification'
  get 'help/star_system_build_specification'
  get 'help/star_system_registration'

  get '/deltas', to: 'marketing#deltas'

  # Defines the root path route ("/")
  root 'marketing#index'
end
