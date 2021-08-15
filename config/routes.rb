Rails.application.routes.draw do
  root to: 'static_pages#top'
  
  get 'login', to: 'session#new'
  post 'login', to: 'session#create'
  delete 'logout', to: 'session#destroy'
  
  resources :password_resets, only: [:new, :create, :edit, :update]
  
  resources :users, only: [:index, :new, :create, :edit, :show, :update, :destroy] do
    get 'attendances/edit_one_month'
    
    patch 'attendances/update_one_month'

    resources :attendances do
      resources :overtime_approvals, only: [:new, :create, :update] do
        member do
          patch 'approve_or_reject'
        end
      end
  
      collection do
        get 'overtime_approvals/overtime_application_notice', to: 'overtime_approvals#overtime_application_notice'
      end
      
      collection do
        get 'change_approvals/attendance_change_application_notice', to: 'change_approvals#attendance_change_application_notice'
      end
      
      resources :change_approvals, only: [:new, :create, :update] do
        member do
          patch 'approve_or_reject'
        end
      end
    end

    collection {post :import}
    member do
      patch 'update_index'
      get 'show_only'
    end

    collection do
      get 'working_employee_list'
    end
  end
end
