class AddQcFileIndex < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :qc_files, :labware, column: :asset_id
  end
end
