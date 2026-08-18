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

  mount MissionControl::Jobs::Engine, at: '/jobs'
  # Mounted at the top level (not inside `namespace :admin`) even though the
  # path is under /admin/faultline: Faultline's own bundled views hardcode
  # route helper calls like `faultline.error_groups_path`, which only exist
  # when the engine's generated route-helper proxy is named plain "faultline"
  # (Rails prefixes that proxy name with the enclosing namespace, e.g.
  # "admin_faultline", if mounted inside `namespace :admin do...end`, which
  # breaks those views). Admin-only access is enforced by Faultline's own
  # `authenticate_with` config (config/initializers/faultline.rb), not by
  # routing.
  mount Faultline::Engine, at: '/admin/faultline'

  namespace :admin do
    root to: 'dashboard#index'

    resources :rulebooks do
      member do
        post :import
        post :rebuild_search_vectors
        patch :toggle_searchable
      end
      resources :rulebook_pages, only: %i[index show update] do
        collection { get :mapping }
      end
    end
  end

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
      patch 'star_systems/:id', to: 'star_systems#update', defaults: { format: :json }
      get 'star_systems/:id/ship_traffic', to: 'star_systems#ship_traffic', defaults: { format: :json }
      get 'stellar_objects/:id', to: 'stellar_objects#show', defaults: { format: :json }
      get 'stellar_objects/:id/moons', to: 'stellar_objects#moons', as: :stellar_object_moons, defaults: { format: :json }
      get 'stellar_objects/:id/cities', to: 'stellar_objects#cities', as: :stellar_object_cities, defaults: { format: :json }
      resources :stars, only: %i[index update]
      get 'map', to: 'map#show'
      get 'jump_route_links', to: 'jump_route_links#index', defaults: { format: :json }
      resources :jump_routes, only: %i[index update destroy], defaults: { format: :json }
      resources :survey_overlays, only: %i[index create update destroy], defaults: { format: :json } do
        member do
          patch :move_up
          patch :move_down
        end
      end
      get 'rogues',        to: 'rogues#index',        defaults: { format: :json }
      get 'map_labels',    to: 'map_labels#index',    defaults: { format: :json }
      get 'star_map',      to: 'star_map#index',      defaults: { format: :json }
      get 'search',        to: 'search#query',        defaults: { format: :json }
      get 'subsector_at',  to: 'subsector_lookup#show', defaults: { format: :json }
      get  'route_plan',         to: 'route_plans#plan',    defaults: { format: :json }
      post 'route_plan/save',    to: 'route_plans#save',    defaults: { format: :json }
      get  'route_plan/systems', to: 'route_plans#systems', defaults: { format: :json }
      get  'passenger_traffic',        to: 'passenger_traffic#calculate', defaults: { format: :json }
      get  'passenger_traffic/system', to: 'passenger_traffic#system',    defaults: { format: :json }
      get  'freight_traffic',        to: 'freight_traffic#calculate', defaults: { format: :json }
      get  'freight_traffic/system', to: 'freight_traffic#system',    defaults: { format: :json }
      get  'mail_traffic',        to: 'mail_traffic#calculate', defaults: { format: :json }
      get  'mail_traffic/system', to: 'mail_traffic#system',    defaults: { format: :json }
      get  'trade_goods/availability', to: 'trade_goods#availability', defaults: { format: :json }
      get  'trade_goods/prices',       to: 'trade_goods#prices',       defaults: { format: :json }
      resources :travel_zones, only: :index, defaults: { format: :json }
      get 'rulebooks/search', to: '/rulebook_search#index', as: :rulebook_search, defaults: { format: :json }
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

    resources :survey_overlays do
      member do
        patch :move_up
        patch :move_down
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

    resource :trade_goods, only: %i[edit update]

    resources :stellar_objects do
      member do
        post :regenerate_characteristics
        get  :daily_traffic
        post :generate_daily_traffic
      end
      resources :cities, only: %i[new create edit update destroy], shallow: true
    end

    resources :social_characteristics_presets, only: %i[index create destroy]

    resources :allegiances do
      collection do
        post 'import_from_traveller_map'
        get 'table'
        get 'search'
      end
      member do
        patch 'toggle_known'
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
        get  :defaults_source
        post :upload_t5
        match :derive_build, via: %i[post patch]
        get :map
        get :strategic_map
        get :resource_map
        get :heat_map
        get :tech_level_map
        get :habitability_map
        get :government_map
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
        post :upload_t5
        post :import_jump_routes
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
    resource :commerce, only: [:show], controller: 'commerce'
    get  '/languages',          to: 'languages#index',    as: :languages
    post '/languages/generate', to: 'languages#generate', as: :generate_languages
    get  '/languages/word',     to: 'languages#word',     as: :language_word
    get '/data-cores', to: 'data_cores#index', as: :data_cores

    get 'library/search',      to: 'rulebook_search#index', as: :rulebook_search
    get 'library/search/more', to: 'rulebook_search#more',  as: :more_rulebook_search

    get   'library', to: 'library#index', as: :library
    patch 'library/:rulebook_id/toggle_enabled',           to: 'library#toggle_enabled',           as: :toggle_enabled_library
    patch 'library/:rulebook_id/toggle_player_searchable', to: 'library#toggle_player_searchable', as: :toggle_player_searchable_library
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
