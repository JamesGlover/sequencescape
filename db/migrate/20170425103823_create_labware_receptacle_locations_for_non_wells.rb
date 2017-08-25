class CreateLabwareReceptacleLocationsForNonWells < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute(%q{
      UPDATE receptacles
      SET receptacles.labware_id = receptacles.id
      WHERE receptacles.sti_type != 'Well';
    })
  end
end
