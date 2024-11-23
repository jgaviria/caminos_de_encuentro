
Rails.application.routes.draw do
  # Devise routes for authentication
  devise_for :users

  # Root paths
  authenticated :user do
    root to: "steps#show", id: "profile", as: :authenticated_root
  end

  unauthenticated do
    root "pages#home"
  end

  # Steps flow
  get '/steps/:id', to: 'steps#show', as: 'step'
  patch '/steps/:id', to: 'steps#update'

  # Other resources
  resources :educations
  resources :family_members
  resources :addresses
  resources :profiles

  get "pages/home"
  
  
end
