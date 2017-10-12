module WorkOrders::Builders
  #
  # Class NullBuilder provides a test builder for work orders
  # that can be used in tests in place of mocks
  #
  # @author Genome Research Ltd.
  #
  class TestBuilder
    attr_reader :test_param

    def initialize(params)
      @test_param = params[:test_param]
    end

    def build(_)
      # Do nothing
    end
  end
end
