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
    class WorkOrderCollectionResource < BaseResource
      has_many :work_orders
      attribute :name
      filter :name
    end
  end
end
