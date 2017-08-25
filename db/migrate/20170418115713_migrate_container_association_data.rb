class MigrateContainerAssociationData < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute(%{
      UPDATE receptacles r
      INNER JOIN container_associations ca ON (ca.content_id = r.id)
      INNER JOIN labware ON labware.id = container_associations.container_associations
      SET r.labware_id = ca.container_id
      WHERE ca.container_id IS NOT NULL
    })
  end
end
