class ConstrainPositionOnContainerAssociations < ActiveRecord::Migration
  def self.up
    change_column(:container_associations, :position_id, :integer, :null => false)
  end

  def self.down
    # Nothing to do here
  end
end
