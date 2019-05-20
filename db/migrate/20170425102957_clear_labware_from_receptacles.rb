class ClearLabwareFromReceptacles < ActiveRecord::Migration[4.2]
  class Receptacle < ActiveRecord::Base
    self.table_name = 'receptacles'
  end

  def change
    Receptacle.where(sti_type:['Plate',*Plate.descendants.map(&:name)]).destroy_all
  end
end
