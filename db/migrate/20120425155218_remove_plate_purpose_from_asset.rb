class RemovePlatePurposeFromAsset < ActiveRecord::Migration
  def self.up
    alter_table :assets do
      remove_column :plate_purpose_id
      remove_column :legacy_sample_id
      remove_column :legacy_tag_id
    end
  end

  def self.down
    say "Restoring plate_purpose column. Note: Run down migration 20120425155148 to restore the data."
    alter_table :assets do
      add_column :plate_purpose_id, :integer
      add_column :legacy_sample_id, :integer
      add_column :legacy_tag_id, :integer
    end
  end
end
