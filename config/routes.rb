require "sidekiq/web"
require "sidekiq/throttled/web"

Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Redirect authenticated users to dashboard
  authenticated :user do
    root "dashboard#index", as: :authenticated_root
  end

  # Set root path to Devise's sign in page for unauthenticated users
  devise_scope :user do
    root "devise/sessions#new"
  end

  resources :keyword_files do
    member do
      get :results
      get :download, defaults: { format: "csv" }
      get :download_original
    end
  end

  # Protect Sidekiq web UI with Devise authentication
  authenticate :user do
    mount Sidekiq::Web => "/sidekiq"
  end
end
