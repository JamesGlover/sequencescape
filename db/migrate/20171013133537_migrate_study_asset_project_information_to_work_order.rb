class MigrateStudyAssetProjectInformationToWorkOrder < ActiveRecord::Migration[5.1]
  def change
    WorkOrder.transaction do
      WorkOrder.includes(:requests).find_each do |work_order|
        request = work_order.requests.first
        work_order.update_attributes!(asset_id: request.asset_id, study_id: request.initial_study_id, project: request.initial_project_id)
      end
    end
  end
end
