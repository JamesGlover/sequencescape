class AddProjectIdStudyIdAssetIdToWorkOrders < ActiveRecord::Migration[5.1]
  def change
    add_reference :work_orders, :asset, foreign_key: true, type: :integer
    add_reference :work_orders, :study, foreign_key: true, type: :integer
    add_reference :work_orders, :project, foreign_key: true, type: :integer
  end
end
