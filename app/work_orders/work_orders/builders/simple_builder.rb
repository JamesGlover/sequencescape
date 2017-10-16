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
    attr_reader :request_type_key

    def initialize(parameters)
      @request_type_key = parameters[:request_type]
    end

    def build(work_order)
      work_order.requests = Array.new(work_order.number) do
        request_type.create!(
          asset: work_order.source_receptacle,
          request_metadata_attributes: work_order.options,
          study: work_order.study,
          project: work_order.project,
          work_order: work_order
        )
      end
      true
    end

    private

    def request_type
      RequestType.find_by(key: request_type_key)
    end
  end
end
