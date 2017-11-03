# frozen_string_literal: true

require_dependency 'app/resources/api/v2/receptacle_resource'

module Api
  module V2
    #
    # Class WorkOrderTypeResource provides a JSONapi
    # implimentation of work order types.
    #
    class WorkOrderTypeResource < BaseResource
      attribute :name, readonly: true
      attribute :friendly_name, readonly: true
      attribute :unit_of_measurement, readonly: true
      attribute :options, readonly: true, delegate: :options_hash
    end
  end
end
