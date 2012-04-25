class PlateTemplate < Plate
end

class NewPlateTemplate < ActiveRecord::Base
  set_table_name "plate_templates"
  serialize :wells, Array
end

class MovePlateTemplatesToNewTable < ActiveRecord::Migration

  def self.up
    ActiveRecord::Base.transaction do
      Plate.find_all_by_sti_type('PlateTemplate').each do |template|
        name = template.name
        size = template.size
        control = template.descriptor_value(:control_well).to_i
        wells_array = template.wells.map {|w| [w.map_description,w.map_id]}
        say "Porting #{name}"
        NewPlateTemplate.create!(:name => name, :size => size, :control_well => control, :wells => wells_array )
        template.destroy
      end
    end
  end

  def self.down
    NewPlateTemplate.all.each do |template|
      name = template.name
      size = template.size
      control = template.control_well
      say "Un-porting #{name}"
      pt = PlateTemplate.create!(:name => name, :size => size )
      template.wells.each do |well|
        pt.add_well_by_map_description(Well.create!(), well.first)
      end
      pt.add_descriptor(Descriptor.new({:name => 'control_well', :value => control}))
      pt.save
      template.destroy
    end
  end
end
