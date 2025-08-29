Rails.application.routes.draw do
  # Locale scope for internationalization
  scope "/:locale", locale: /#{I18n.available_locales.join("|")}/ do
    # Devise routes for user authentication
    devise_for :users

    # Root path for authenticated and unauthenticated users
    authenticated :user do
      root to: "dashboards#show", as: :authenticated_root
    end

    unauthenticated do
      root to: "landing_page#home", as: :unauthenticated_root
    end

  get "dashboard", to: "dashboards#show", as: :dashboard


  resources :matches, only: [ :index, :show, :destroy ] do
    member do
      patch "verify"
    end
  end

  namespace :admin do
    resources :matches do
      collection do
        post "bulk_verify"
        post "bulk_reject"
        get "export"
      end
      member do
        patch "verify"
        delete "reject"
      end
    end
  end

  # Resourceful routes for personal information, addresses, and search profiles
  resource :personal_info, only: [ :new, :create, :edit, :update ]
  resource :address, only: [ :new, :create, :edit, :update ]
  resources :search_profiles, only: [ :index, :show, :new, :create, :edit, :update, :destroy ] do
    collection do
      get "step1"  # Basic info step
      post "step1"
      get "step2"  # Location info step
      post "step2"
      get "step3"  # Review and create step
      post "step3"
    end
    member do
      post "match"
      get "edit_step1"   # Edit step 1
      patch "edit_step1"
      get "edit_step2"   # Edit step 2
      patch "edit_step2"
      get "edit_step3"   # Edit step 3
      patch "edit_step3"
    end
  end

  # Health check route
  get "up", to: "rails/health#show", as: :rails_health_check

  # PWA service worker and manifest routes
  get "service-worker", to: "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest", to: "rails/pwa#manifest", as: :pwa_manifest

    # Custom route for user sign-out
    devise_scope :user do
      delete "users/sign_out", to: "devise/sessions#destroy"
    end
  end

  # Root redirect to default locale
  root to: redirect("/#{I18n.default_locale}")
end
