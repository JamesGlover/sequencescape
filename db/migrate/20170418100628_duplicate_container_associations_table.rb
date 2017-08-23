class DuplicateContainerAssociationsTable < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute('CREATE TABLE labware_receptacles LIKE container_associations')
    ActiveRecord::Base.connection.execute('INSERT labware_receptacles SELECT * FROM container_associations')
  end

  def down
    drop_table :labware_receptacles
  end
end
