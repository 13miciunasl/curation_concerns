module CurationConcerns
  module AdminControllerBehavior
    extend ActiveSupport::Concern

    included do
      cattr_accessor :configuration
      self.configuration = CurationConcerns.config.dashboard_configuration
      before_action :require_permissions
      before_action :load_configuration
      layout "admin"
    end

    def index
      render "index"
    end

    private

    def require_permissions
      authorize! :read, :admin_dashboard
    end

    def load_configuration
      @configuration = self.class.configuration.with_indifferent_access
    end

    ##
    # Loads the index action if it's only defined in the configuration.
    def action_missing(action)
      if @configuration[:actions].include?(action)
        index
      else
        super
      end
    end

  end
end