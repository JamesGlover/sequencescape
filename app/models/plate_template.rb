class PlateTemplate < ActiveRecord::Base

  serialize :wells

  def update_params!(details = {})
    self.name = details[:name]
    self.wells = []
    self.size = (details[:rows]).to_i * (details[:cols]).to_i
    set_control_well(details[:control_well]) unless set_control_well(details[:control_well]).nil?
    unless details[:wells].nil?
      self.wells = details[:wells].map {|k,v| [k,v.to_i]}
    end
    self.save!
  end

  def set_control_well(result)
    self.control_well = result
    self.save!
  end

  def find_well_by_name(well)
    self.wells.detect {|w| w.first == well }
  end

  def add_well(well, row=nil, col=nil)
    self.wells ||= []
    self.wells << [well.map_description, well.map_id]
    self.save!
  end
  alias :add_and_save_well :add_well

  def before_create
    self.wells ||= []
  end

end
