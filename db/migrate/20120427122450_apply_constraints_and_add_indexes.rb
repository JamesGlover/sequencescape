class ApplyConstraintsAndAddIndexes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      say 'Adding Indexes'
      add_index :plate_metadata, :plate_purpose_id
      remove_index :plate_metadata, :plate_purpose_id
      add_index :plate_metadata, :plate_purpose_id, { :unique => true}
      say 'Applying Foreign Key Constraints'
      connection.execute(
        'ALTER TABLE plate_metadata
        ADD CONSTRAINT
          FOREIGN KEY fk_plate_metadata_to_plate_purpose (plate_purpose_id)
          REFERENCES plate_purposes (id);'
      )

    end
  end

  def self.down
    remove_index :plate_metadata, :plate_purpose_id
    remove_index :plate_metadata, :plate_purpose_id
    add_index :plate_metadata, :plate_purpose_id, { :unique => false}
    connection.execute(
      'ALTER TABLE Orders
      DROP FOREIGN KEY fk_plate_metadata_to_plate_purpose;'
    )
  end
end
