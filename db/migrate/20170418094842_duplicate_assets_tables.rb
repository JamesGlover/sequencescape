class DuplicateAssetsTables < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute('CREATE TABLE receptacles LIKE assets')
    ActiveRecord::Base.connection.execute('INSERT receptacles SELECT * FROM assets')
    ActiveRecord::Base.connection.execute('CREATE TABLE labware LIKE assets')
    ActiveRecord::Base.connection.execute('INSERT labware SELECT * FROM assets')
  end

  def down
    drop_table :receptacles
    drop_table :labware
  end
end
