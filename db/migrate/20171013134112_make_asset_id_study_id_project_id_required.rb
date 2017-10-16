class MakeAssetIdStudyIdProjectIdRequired < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:work_orders, :asset_id, false)
    change_column_null(:work_orders, :study_id, false)
    change_column_null(:work_orders, :project_id, false)
  end
end
