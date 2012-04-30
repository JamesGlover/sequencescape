class AddPlatePurposeToPlateMetadata < ActiveRecord::Migration
  def self.up
    alter_table :plate_metadata do
      add_column :plate_purpose_id, :integer, :null=>false
      change_column :plate_id, :integer, :null => false
    end
  end

  def self.down
    alter_table :plate_metadata do
      remove_column :plate_purpose_id
      change_column :plate_id, :integer, :null => true
    end
  end
end
