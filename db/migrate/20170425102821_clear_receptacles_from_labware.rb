class ClearReceptaclesFromLabware < ActiveRecord::Migration[4.2]
  class Labware < ActiveRecord::Base
    self.table_name = 'labware'
  end

  def change
    Labware.where(sti_type:['Well']).destroy_all
  end
end
