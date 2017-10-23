module WorkOrders
  #
  # Class WorkOrders::WorkOrderType tracks configuration for
  # work order types.
  #
  # @author Genome Research Ltd.
  #
  class WorkOrderType
    include ConfigurationLoader::Equality

    attr_reader :friendly_name, :builder, :name, :options
    def initialize(name, config)
      @name = name
      @friendly_name = config.fetch('friendly_name', name.humanize)
      self.builder = config['builder'] || Builders.default
      self.options = config['options'] || {}
    end

    def builder=(builder_config)
      builder_class = builder_config.fetch(:builder_class)
      params = builder_config.fetch(:params, nil)
      @builder = Builders.builder_for(builder_class).new(params)
    end

    def options=(options_config)
      @options = Options.new(options_config)
    end
  end
end
