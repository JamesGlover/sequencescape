class CreateLabwareReceptacleLocationsForNonWells < ActiveRecord::Migration[4.2]
  def up
    ActiveRecord::Base.connection.execute(%q{
      UPDATE receptacles
      SET receptacles.labware_id = receptacles.id
      WHERE receptacles.sti_type != 'Well';
    })
  end
end
