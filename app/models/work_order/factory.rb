# frozen_string_literal: true

require_dependency 'work_order'

class WorkOrder
  # Builds work orders for a given submission
  # Currently only supports single request type submissions.
  class Factory
    include ActiveModel::Validations
    attr_reader :submission

    validates :number_of_request_types, numericality: { equal_to: 1 }

    delegate :requests, to: :submission

    def initialize(submission, unit_of_measurement:)
      @submission = submission
      @unit_of_measurement = unit_of_measurement
    end

    def create_work_orders!
      requests.group_by(&:asset_id).map do |asset_id, requests|
        state = requests.first.state
        WorkOrder.create!(
          work_order_type: work_order_type,
          requests: requests,
          asset_id: asset_id,
          study_id: requests.first.initial_study_id,
          project_id: requests.first.initial_project_id,
          number: requests.length,
          state: state
          unit_of_measurement: @unit_of_measurement)
      end
    end

    private

    def number_of_request_types
      requests.map(&:request_type_id).uniq.count
    end

    def work_order_type
      @work_order_type ||= WorkOrderType.find_or_create_by!(name: requests.first.request_type.key)
    end
  end
end
