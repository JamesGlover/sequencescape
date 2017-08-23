class RenameAssetsTable < ActiveRecord::Migration
  def change
    rename_table 'assets', 'assets_deprecated'
  end
end
