class AddPrefixToPlatePurpose < ActiveRecord::Migration

  def self.up
    add_column :plate_purposes, :barcode_prefix_id, :integer, :null => false, :default => BarcodePrefix.find_by_prefix('DN').id
  end

  def self.down
    remove_column :plate_purposes, :barcode_prefix_id
  end
end
