require 'active_attr'
module Worthwhile
  class ClassifyConcern
    include ActiveAttr::Model
    attribute :curation_concern_type

    validates(
      :curation_concern_type,
      presence: true,
      inclusion: { in: lambda { |record| record.registered_curation_concern_types } }
    )

    def all_curation_concern_classes
      registered_curation_concern_types.sort.map { |c| self.class.to_class(c) }
    end

    def registered_curation_concern_types
      Worthwhile.configuration.registered_curation_concern_types
    end

    def possible_curation_concern_types
      registered_curation_concern_types.collect do |concern|
        [self.class.to_class(concern).human_readable_type, concern]
      end
    end

    def curation_concern_class
      if possible_curation_concern_types.detect{|name, class_name|
          class_name == curation_concern_type
        }
        self.class.to_class(curation_concern_type)
      else
        raise RuntimeError, "Invalid :curation_concern_type"
      end
    end

    def self.to_class(type)
      # TODO we may want to allow a different (or nil) namespace
      "Worthwhile::#{type}".constantize
    end
  end
end
