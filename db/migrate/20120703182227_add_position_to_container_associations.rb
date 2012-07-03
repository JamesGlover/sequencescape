class AddPositionToContainerAssociations < ActiveRecord::Migration
  def self.up
    alter_table(:container_associations) do |t|
      t.add_column(:position_id, :integer)
      t.add_index([:container_id, :position_id], :name => 'unique_positions_on_plate_idx', :unique => true)
    end
  end

  def self.down
    alter_table(:container_associations) do |t|
      t.remove_column(:position_id)
      t.remove_index(:name => 'unique_positions_on_plate_idx')
    end
  end
end
