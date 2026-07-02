Rails.application.routes.draw do
  # Public routes — no campaign slug
  root 'marketing#index'
  resource :session
  resources :registrations
  resources :passwords, param: :token
  resources :campaigns, only: %i[new create]
  resource :tour_completion, only: [:create]

  get '/fairuse', to: 'marketing#fairuse'
  get '/deltas',  to: 'release_notes#index'
  get '/help',       to: 'help#index'
  get '/help/:page', to: 'help#show',  as: :help_page

  get 'up' => 'rails/health#show', as: :rails_health_check

  # Campaign-scoped routes — all prefixed with /c/:campaign_slug
  scope '/c/:campaign_slug' do
    get '/', to: redirect { |params, _req| "/c/#{params[:campaign_slug]}/sectors" }, as: :campaign_root
    get 'starmap', to: 'starmaps#show', as: :campaign_starmap
    namespace :api do
      resources :sectors, only: :index, defaults: { format: :json }
      resources :subsectors, only: :show, defaults: { format: :json }
      resources :regions, only: :index, defaults: { format: :json }
      resources :parsecs, only: :index
      get  'jumps',       to: 'jump_logs#index', defaults: { format: :json }
      post 'jumps',       to: 'jump_logs#create', defaults: { format: :json }
      resources :ships, only: :index, defaults: { format: :json } do
        member do
          get :last_jump
        end
      end
      get 'starsystems', to: 'star_systems#index', defaults: { format: :json }
      get 'starsystem',  to: 'star_system#show', defaults: { format: :json }
      get 'star_systems/:id', to: 'star_systems#show', defaults: { format: :json }
      get 'stellar_objects/:id', to: 'stellar_objects#show', defaults: { format: :json }
      resources :stars, only: %i[index update]
      get 'map', to: 'map#show'
      get 'jump_route_links', to: 'jump_route_links#index', defaults: { format: :json }
      get 'rogues',        to: 'rogues#index',        defaults: { format: :json }
      get 'star_map',      to: 'star_map#index',      defaults: { format: :json }
      get 'search',        to: 'search#query',        defaults: { format: :json }
    end

    resources :jump_logs

    resources :jump_route_links, only: %i[create destroy]

    resources :jump_routes do
      member do
        get :export_links
        get :export_path
        get :map
      end
      resource :jump_route_import, only: %i[create]
    end

    resources :ships do
      collection do
        get :new_modal
      end
    end

    resources :regions do
      member do
        get  :import_hexes
        post :upload_hexes
        get  :download_csv
      end
    end

    resources :tech_levels
    resources :governments
    resources :law_levels
    resources :facilities
    resources :travel_zones

    resources :trade_codes do
      collection do
        post 'import_t5'
      end
    end

    resources :stellar_objects do
      member do
        post :regenerate_characteristics
        get  :daily_traffic
        post :generate_daily_traffic
      end
    end

    resources :social_characteristics_presets, only: %i[index create destroy]

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
        post :derive_build
        get  :map
        get  :select_main_world
        patch :set_main_world
        patch :update
        get  :edit_bases
        post :update_bases
        get  :edit_trade_codes
        post :update_trade_codes
        get  :assign_social_characteristics
        post :apply_social_characteristics
        get  :link_modal
        get  :quick_link
        get  :jump_map
        get  :jump_map_modal
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
        match :derive_build, via: %i[post patch]
        get :map
        get :strategic_map
        get :resource_map
        get :heat_map
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
        post :generate,  as: :generate
        post :load_defaults
        get  :defaults_source
        get  :map
        get  :poster
      end
      resources :rogues, only: %i[index new create destroy]
      resources :star_systems, only: %i[new create index destroy]
    end

    get '/search',              to: 'search#query'
    get '/search/star-systems', to: 'search#star_systems', as: :search_star_systems
    resource :route_plan, only: [:new] do
      collection do
        post :save
        delete :clear
      end
    end
    get  '/languages',          to: 'languages#index',    as: :languages
    post '/languages/generate', to: 'languages#generate', as: :generate_languages
    get  '/languages/word',     to: 'languages#word',     as: :language_word
    get '/data-cores', to: 'data_cores#index', as: :data_cores
    resource :campaign_settings, only: %i[show edit update], path: 'settings/campaign' do
      post :populate_deepnight
      post :assign_builds
      post :populate_all
      post :populate_empty
      post :regenerate_all
      post :generate_all_sectors_map
      post :regenerate_api_token
    end

    get 'all_sectors_map', to: 'all_sectors_maps#show', as: :campaign_all_sectors_map
  end
end
