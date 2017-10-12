module WorkOrders
  #
  # Class WorkOrders::WorkOrderType tracks configuration for
  # work order types.
  #
  # @author Genome Research Ltd.
  #
  class WorkOrderType
    attr_reader :friendly_name, :builder
    def initialize(name, config)
      @name = name
      @friendly_name = config.fetch('friendly_name', name.humanize)
      self.builder = config['builder'] || Builders.default
    end

    def builder=(builder_options)
      builder_class = builder_options.fetch(:builder_class)
      params = builder_options.fetch(:params, nil)
      @builder = Builders.builder_for(builder_class).new(params)
    end
  end
end
