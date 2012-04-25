class AddHiddenFlagToPlatePurposes < ActiveRecord::Migration
  def self.up
    add_column :plate_purposes, :visible, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :plate_purposes, :visible
  end
end
