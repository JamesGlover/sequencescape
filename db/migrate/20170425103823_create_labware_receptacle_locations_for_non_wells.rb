class CreateLabwareReceptacleLocationsForNonWells < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute(%q{
      INSERT labware_receptacles
      (receptacle_id, labware_id, position_index)
      SELECT receptacles.id AS receptacle_id, receptacles.id AS labware_id, 0 AS position_index
      FROM receptacles
      WHERE receptacles.sti_type != 'Well'
      ORDER BY receptacles.id ASC;
    })
  end
end
