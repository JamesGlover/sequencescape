class CreatePlateTempleateTable < ActiveRecord::Migration

  class PlateTemplate < ActiveRecord::Base
  end

  def self.up
    ActiveRecord::Base.transaction do
      create_table :plate_templates do |t|
        t.string :name, :null => false
        t.text :wells
        t.integer :size, :null => false
        t.boolean :control_well
      end

      add_index(:plate_templates, :name, :unique => true)
    end
  end

  def self.down
      drop_table :plate_templates
  end
end
