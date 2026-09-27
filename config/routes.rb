Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "boards#index"

  resource :session, only: %i[new create destroy]
  resource :profile, only: %i[update]

  resources :boards do
    member do
      get :export
      patch :toggle_hidden
    end
    resource :timer, only: %i[create update destroy], controller: "timers"

    resources :cards, only: %i[create update destroy], shallow: true do
      member do
        patch :move
        post :merge
        post :unmerge
      end
      resources :votes, only: %i[create] do
        collection { delete :destroy }
      end
      resources :comments, only: %i[create destroy]
    end
  end
end
