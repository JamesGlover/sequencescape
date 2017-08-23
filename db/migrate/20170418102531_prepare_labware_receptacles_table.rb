class PrepareLabwareReceptaclesTable < ActiveRecord::Migration
  def change
    change_table 'labware_receptacles' do |t|
      t.column :position_index, :integer
    end
    rename_column 'labware_receptacles', 'container_id', 'labware_id'
    rename_column 'labware_receptacles', 'content_id', 'receptacle_id'
    add_index 'labware_receptacles', ['labware_id', 'position_index'], unique: true
  end
end
