module WorkOrders::Builders
  #
  # Class NullBuilder provides a default builder for work orders
  # that does nothing.
  #
  # @author Genome Research Ltd.
  #
  class NullBuilder
    include ConfigurationLoader::Equality

    def initialize(*_args)
      # Do nothing
    end

    def build(_)
      # Do nothing
    end
  end
end
