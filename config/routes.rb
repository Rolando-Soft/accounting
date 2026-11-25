Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :setup, only: %i[ new create ]
  resources :entries do
    collection do
      post :reconcile
    end
  end
  resources :journal_transactions do
    collection do
      get :payee_suggestions
    end
  end
  resources :accounts, except: :show
  resources :workspaces, except: :show do
    member do
      post :switch
      get :delete_confirm
    end
  end

  get "reports", to: "reports#index", as: :reports
  get "reports/balance_sheet", to: "reports#balance_sheet", as: :balance_sheet
  get "reports/income_statement", to: "reports#income_statement", as: :income_statement
  get "reports/cash_flow_statement", to: "reports#cash_flow_statement", as: :cash_flow_statement
  get "reports/cash_flow_diagram", to: "reports#cash_flow_diagram", as: :cash_flow_diagram
  get "reports/funds_flow_diagram", to: "reports#funds_flow_diagram", as: :funds_flow_diagram
  get "reports/account_ledger", to: "reports#account_ledger", as: :account_ledger
  get "reports/expense_treemap", to: "reports#expense_treemap", as: :expense_treemap
  get "reports/income_expense_comparison", to: "reports#income_expense_comparison", as: :income_expense_comparison
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
   root "entries#index"
end
