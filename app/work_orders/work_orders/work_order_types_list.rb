module WorkOrders
  # Exceptions
  # Raised if we try to look up a missing work order
  ConfigNotFound = Class.new(StandardError)

  #
  # Class WorkOrderTypesList provides a means of loading
  # in work order configurations, and retrieving them by either
  # the internal name, or a more friendly human readable name
  #
  # @author Genome Research Ltd.
  #
  class WorkOrderTypesList
    include ConfigurationLoader::Equality

    def initialize(config)
      @work_order_types = {}
      @friendly_name_to_name = {}
      config.each { |name, type_config| register_work_order(name, type_config) }
    end

    #
    # Find a work order config by name. Raised ConfigNotFound for missing work orders
    #
    # @param [String] name The standard name of the work order.
    #
    # @return [WorkOrders::WorkOrderType] The matching Work Order configuration
    #
    def find(name)
      @work_order_types[name] || raise(ConfigNotFound, "Could not find '#{name}' in work_orders configuration")
    end

    #
    # Convert human readable names into standard names.
    # - Removes extra spaces
    # - Is case insensitive
    # - Returns nil for no matches
    #
    # @param [String] human_name A human readable version of the work order.
    #
    # @return [String] The standard name for the work order
    #
    def name_from(human_name)
      @friendly_name_to_name[human_name.squish.downcase]
    end

    private

    def register_work_order(name, config)
      new_type = WorkOrderType.new(name, config)
      @work_order_types[name] = new_type
      @friendly_name_to_name[new_type.friendly_name.downcase] = name
    end
  end
end
