Ergonaut::Application.routes.draw do

  resources :statistics, only: [:index, :show] do
  end

  resources :author_center, only: [:index, :new, :create] do
    member do
      get 'withdraw'
    end
    collection do
      get 'archives'
    end
    resources :revisions, only: [:new, :create]
    resources :referee_assignments, only: [:show]
  end

  resources :referee_center, only: [:index, :show] do
    member do
      get 'edit_response'
      put 'update_response'
      get 'edit_report'
      put 'update_report'
    end
    collection do
      get 'archives'
    end
  end

  resources :one_click_edits, only: [:show]

  resources :one_click_reviews do
    member do
      get 'agree'
      get 'decline'
      put 'record_decline_comments'
    end
  end

  resources :submissions, except: [:new] do
    member do
      get 'edit_manuscript_file'
      put 'update_manuscript_file'
    end
    resources :referee_assignments, only: [:new, :create, :show, :destroy] do
      resources :sent_emails, only: [:index, :show]
      collection do
        post 'select_existing_user'
        post 'register_new_user'
      end
      member do
        get 'agree_on_behalf'
        get 'decline_on_behalf'
        get 'edit_due_date'
        put 'update_due_date'
        get 'edit_report'
        put 'update_report'
      end
    end
    resources :sent_emails, only: [:index, :show]
  end
  # Reroute download links (Carrierwave is configured to store in private dir)
  match "/uploads/submission/manuscript_file/:id/manuscript*ext", controller: "submissions", action: "download", conditions: { method: :get }
  match "/uploads/referee_assignment/attachment_for_editor/:id/attachment*ext", controller: "referee_assignments", action: "download_attachment_for_editor", conditions: { method: :get }
  match "/uploads/referee_assignment/attachment_for_author/:id/attachment*ext", controller: "referee_assignments", action: "download_attachment_for_author", conditions: { method: :get }
  # For testing, we need similar reroutes into '/spec/support'
  match "/spec/support/uploads/submission/manuscript_file/:id/manuscript*ext", controller: "submissions", action: "download", conditions: { method: :get }
  match "/spec/support/uploads/referee_assignment/attachment_for_editor/:id/attachment*ext", controller: "referee_assignments", action: "download_attachment_for_editor", conditions: { method: :get }
  match "/spec/support/uploads/referee_assignment/attachment_for_author/:id/attachment*ext", controller: "referee_assignments", action: "download_attachment_for_author", conditions: { method: :get }

  resources :archives, only: [:index, :show, :update] do
    resources :sent_emails, only: [:index, :show]
    resources :referee_assignments, only: [:show] do
      resources :sent_emails, only: [:index, :show]
    end
  end

  resources :journal_settings, only: [:index, :edit, :update] do
    member do
      get 'show_email_template'
      post 'create_area'
      delete 'remove_area'
    end
  end

  resources :areas, only: [:create, :destroy]
  resources :users, only: [:index, :new, :show, :create, :edit, :update] do
    collection do
      post 'fuzzy_search'
    end
    member do
      put 'update_gender'
    end
  end
  resources :sessions, only: [:new, :create, :destroy]
  resources :password_resets
  resources :reminders, only: [:index] do
    collection do
      get 'overdue_responses'
      get 'report_due_soon'
      get 'overdue_reports'
      get 'overdue_internal_reviews'
      get 'reports_complete'
      get 'overude_decision_based_on_external_reviews'
      get 'overdue_area_editor_assignments'
      get 'overdue_decision_approval'
    end
  end

  root to: 'submissions#index', constraints: lambda { |req|
    token = req.cookies['remember_token']
    User.find_by_remember_token(token).editor? if token && User.find_by_remember_token(token)
  }
  root to: 'referee_center#index', constraints: lambda { |req|
    token = req.cookies['remember_token']
    User.find_by_remember_token(token).has_pending_referee_assignments? if token && User.find_by_remember_token(token)
  }
  root to: 'author_center#index', constraints: lambda { |req|
    token = req.cookies['remember_token']
    !User.find_by_remember_token(token).has_pending_referee_assignments? if token && User.find_by_remember_token(token)
  }
  root to: 'static_pages#about'

  match '/',                to: 'static_pages#index'
  match '/guide',           to: 'static_pages#guide'
  match '/about',           to: 'static_pages#about'
  match '/peer_review',     to: 'static_pages#peer_review'
  match '/contact',         to: 'static_pages#contact'
  match '/security_breach', to: 'static_pages#security_breach'
  match '/signup',          to: 'users#new'
  match '/signin',          to: 'sessions#new'
  match '/signout',         to: 'sessions#destroy', via: :delete
end
