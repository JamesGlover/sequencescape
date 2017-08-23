class MigrateMapLocationData < ActiveRecord::Migration
  def change
    ActiveRecord::Base.connection.execute(%q{
      INSERT labware_receptacles
      (receptacle_id, labware_id, position_index)
      SELECT content_id AS receptacle_id, container_id AS labware_id, column_order AS position_index
      FROM container_associations AS ca
      LEFT OUTER JOIN assets ON assets.id = ca.content_id
      LEFT OUTER JOIN maps ON assets.map_id = maps.id
      ORDER BY content_id ASC;
    })
  end
end
