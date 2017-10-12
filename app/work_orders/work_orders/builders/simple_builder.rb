module WorkOrders::Builders
  #
  # Class SimpleBuilder provides builder for constructing requests
  # for ultra-lightweight work-orders, such as those used by traction.
  # It is likely they will be able to be replaces with NullBuilders
  # in the near future.
  #
  # @author Genome Research Ltd.
  #
  class SimpleBuilder
    def initialize(parameters)
      # Do nothing
    end

    def build(_work_order)
      true
    end
  end
end
