Rails.application.routes.draw do
  # Public routes — no campaign slug
  root 'marketing#index'
  resource :session
  resources :registrations
  resources :passwords, param: :token
  resources :campaigns, only: %i[new create]

  get '/fairuse', to: 'marketing#fairuse'
  get '/deltas',  to: 'release_notes#index'
  get '/help', to: 'help#index'
  get 'help/subsector_build_specification'
  get 'help/star_system_build_specification'
  get 'help/star_system_registration'

  get 'up' => 'rails/health#show', as: :rails_health_check

  # Campaign-scoped routes — all prefixed with /c/:campaign_slug
  scope '/c/:campaign_slug' do
    get '/', to: redirect { |params, _req| "/c/#{params[:campaign_slug]}/sectors" }, as: :campaign_root
    get 'starmap', to: 'starmaps#show', as: :campaign_starmap
    namespace :api do
      resources :sectors, only: :index, defaults: { format: :json }
      resources :regions, only: :index, defaults: { format: :json }
      resources :parsecs, only: :index
      get 'jumps',       to: 'jump_logs#index', defaults: { format: :json }
      get 'starsystems', to: 'star_systems#index', defaults: { format: :json }
      get 'starsystem',  to: 'star_system#show', defaults: { format: :json }
      resources :stars, only: %i[index update]
      get 'map', to: 'map#show'
    end

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
      resources :region_components, only: :destroy do
        member do
          get  :hex_template
          get  :import_hexes
          post :upload_hexes
        end
      end
    end

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
        get  :replace
        post :do_replace
        get  :map
        get  :select_main_world
        patch :set_main_world
        patch :update
        get  :edit_bases
        post :update_bases
        get  :edit_trade_codes
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
        get  :populate, as: :populate
        post :generate,  as: :generate
        get  :star_systems_table
        post :load_defaults
        get  :map
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
        get  :populate, as: :populate
        post :generate,  as: :generate
        post :load_defaults
        get  :defaults_source
        get  :map
      end
      resources :rogues, only: %i[index new create destroy]
      resources :star_systems, only: %i[new create index destroy]
    end

    get '/search',   to: 'search#query'
    get '/settings', to: 'settings#index'
    resource :campaign_settings, only: %i[show edit update], path: 'settings/campaign' do
      post :populate_deepnight
      post :assign_builds
      post :populate_all
      post :populate_empty
    end
  end
end
