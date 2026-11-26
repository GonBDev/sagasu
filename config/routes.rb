Rails.application.routes.draw do
  devise_for :users, controllers: { registrations: "users/registrations" }
  root to: "pages#home"
  get "dashboard", to: "dashboards#show", as: :dashboard
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  resources :projects, only: %i[index new create show] do
    member do # Route each workspace step through the existing project show action.
      get "bidder-list/materials", to: "projects#show", as: :bidder_list_materials, defaults: { workspace_step: "materials" }
      get "bidder-list/groups", to: "projects#show", as: :bidder_list_groups, defaults: { workspace_step: "groups" }
      get "bidder-list/suppliers", to: "projects#show", as: :bidder_list_suppliers, defaults: { workspace_step: "suppliers" }
      get "bidder-list/approval", to: "projects#show", as: :bidder_list_approval, defaults: { workspace_step: "approval" }
      post "bidder-list/approval", to: "projects#submit_approval", as: :submit_bidder_list_approval
    end

    resources :bidder_list_versions, only: %i[create show]

    resources :items, only: %i[create edit update] do
      post :preview_import, on: :collection
      post :import, on: :collection
    end
    resources :item_groups, only: %i[create update destroy] do
      post :suggest_suppliers, on: :member
      patch :shortlist_supplier, on: :member
      post :propose, on: :collection
      post :apply_proposal, on: :collection
    end
  end

  get "messages", to: "chats#index", as: :messages
  resources :chats, only: %i[show create] do
    post :notes, on: :collection
    resources :messages, only: :create
  end

  resources :approvals, only: :index do
    patch :decide, on: :member
  end

  resources :suppliers, only: %i[index show]

    resources :users, only: [] do # Scope role changes to the target account.
    resources :user_roles, only: %i[create destroy] # Expose grant and revoke actions.
  end # Close the nested user routes.
end
