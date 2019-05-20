class RenameAssetsTable < ActiveRecord::Migration[4.2]
  def change
    rename_table 'assets', 'assets_deprecated'
  end
end
