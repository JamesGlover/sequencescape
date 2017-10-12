module WorkOrders
  #
  # Module Builders provides a namespace for work order builders.
  # A work order type can be configures with a particular builder to
  # perform operations when the work order is ready. This can be used
  # for legacy pipelines, where work is not driven by work orders directly.
  #
  # @author Genome Research Ltd.
  #
  module Builders
    def self.builder_for(class_name)
      const_get(class_name)
    end

    #
    # Used when no builder is specified
    #
    #
    # @return [Hash] Configuration for an inactive builder object
    #
    def self.default
      {
        builder_class: 'NullBuilder',
        params: nil
      }
    end
  end
end
