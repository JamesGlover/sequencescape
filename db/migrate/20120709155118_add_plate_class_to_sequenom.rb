class AddPlateClassToSequenom < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('Sequenom').update_attributes!(:target_type => 'SequenomQcPlate')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('Sequenom').update_attributes!(:target_type => nil)
    end
  end
end
