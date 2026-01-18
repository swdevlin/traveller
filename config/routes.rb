Rails.application.routes.draw do
  resources :allegiances
  resources :trade_codes
  resources :stellar_objects

  resources :parsecs, only: %i[index show edit update] do
    resources :rogues, only: %i[new create index destroy]
    resources :star_systems, only: %i[new create index destroy]
  end

  resources :star_systems

  resources :stars, only: %i[index show edit update destroy]

  resources :subsectors, only: %i[index show edit update] do
    member do
      post :clear
      get :populate, as: :populate
      post :generate, as: :generate
    end
    resources :rogues, only: %i[new create index destroy]
    resources :star_systems, only: %i[new create index destroy]
  end

  resources :sectors do
    member do
      post :clear
      get :populate, as: :populate
      post :generate, as: :generate
    end
    resources :rogues, only: %i[index new create destroy]
    resources :star_systems, only: %i[new create index destroy]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check
  get 'status/job_count' => 'status#job_count', as: :job_count

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get '/fairuse', to: 'marketing#fairuse', as: :fairuse

  # Defines the root path route ("/")
  root 'marketing#index'
end
