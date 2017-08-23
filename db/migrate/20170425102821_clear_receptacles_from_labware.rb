class ClearReceptaclesFromLabware < ActiveRecord::Migration
  class Labware < ActiveRecord::Base
    self.table_name = 'labware'
  end

  def change
    Labware.where(sti_type:['Well']).destroy_all
  end
end
