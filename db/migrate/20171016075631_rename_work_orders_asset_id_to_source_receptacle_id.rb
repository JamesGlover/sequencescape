class RenameWorkOrdersAssetIdToSourceReceptacleId < ActiveRecord::Migration[5.1]
  def change
    rename_column :work_orders, :asset_id, :source_receptacle_id
  end
end
