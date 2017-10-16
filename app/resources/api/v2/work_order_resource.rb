# frozen_string_literal: true

require_dependency 'app/resources/api/v2/receptacle_resource'

module Api
  module V2
    #
    # Class WorkOrderResource provides an abstraction of
    # request for exposure to external applications. It
    # is intended to allow us to update the internal
    # representation, while maintaining an external
    # interface
    #
    class WorkOrderResource < BaseResource
      default_includes [{ example_request: :request_metadata }, :work_order_type]

      has_one :study, readonly: true
      has_one :project, readonly: true
      has_one :source_receptacle, readonly: true, polymorphic: true
      has_many :samples, readonly: true

      attribute :order_type, readonly: true
      attribute :quantity, readonly: true
      attribute :state
      attribute :options
      attribute :at_risk

      filter :state
      filter :order_type, apply: (lambda do |records, value, _options|
        records.where(work_order_types: { name: value })
      end)

      def quantity
        {
          number: _model.number,
          unit_of_measurement: _model.unit_of_measurement
        }
      end

      def order_type
        _model.work_order_type.name
      end
    end
  end
end
