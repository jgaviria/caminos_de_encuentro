Rails.application.routes.draw do
  # Devise routes for user authentication
  devise_for :users

  # Root path for authenticated and unauthenticated users
  authenticated :user do
    root to: "dashboards#show", as: :authenticated_root
  end

  get 'dashboard', to: 'dashboards#show', as: :dashboard
  
  unauthenticated do
    root to: "landing_page#home", as: :unauthenticated_root
  end

  # Resourceful routes for personal information, addresses, and search profiles
  resource :personal_info, only: [:new, :create, :edit, :update]
  resource :address, only: [:new, :create, :edit, :update]
  resources :search_profiles, only: [:new, :create, :edit, :update]

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
