class AddContainerAssociationColumnsToReceptacle < ActiveRecord::Migration[4.2]
  def up
    add_reference :receptacles, :labware, foreign_key: true
  end

  def down
    remove_reference :receptacles, :labware
  end
end
