module ActionDispatch::Routing
  class Mapper
    def worthwhile_collections
      resources 'collections' do
        collection do
          get :add_member_form
          put :add_member
          put :remove_member
        end
      end
    end
    
    def worthwhile_curation_concerns 
      resources :downloads, only: [:show]
      namespace :curation_concern, path: :concern do
        Worthwhile.configuration.registered_curation_concern_types.map(&:tableize).each do |curation_concern_name|
          namespaced_resources curation_concern_name, except: [:index]
        end
        resources( :permissions, only:[]) do
          member do
            get :confirm
            post :copy
          end
        end
        resources :linked_resources, only: [:new, :create], path: 'container/:parent_id/linked_resources'
        resources :linked_resources, only: [:show, :edit, :update, :destroy]
        resources :generic_files, only: [:new, :create], path: 'container/:parent_id/generic_files'
        resources :generic_files, only: [:show, :edit, :update, :destroy] do
          member do
            get :versions
            put :rollback
          end
        end
      end
    end
    
    private
    # Namespaces routes appropriately
    # @example route_namespaced_target("worthwhile/generic_work") is equivalent to
    #   namespace "worthwhile" do
    #     resources "generic_work", except: [:index]
    #   end
    def namespaced_resources(target, opts={})
      if target.include?("/")
        the_namespace = target[0..target.index("/")-1]
        new_target = target[target.index("/")+1..-1]
        namespace the_namespace do 
          namespaced_resources(new_target, opts)
        end
      else
        resources target, opts
      end
    end
  end
end
