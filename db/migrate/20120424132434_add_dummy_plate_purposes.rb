class PlatePurposes < ActiveRecord::Base
  belongs_to :barcode_printer_type
  belongs_to :barcode_prefix
end

class BarcodePrinterType < ActiveRecord::Base
end

class BarcodePrefix < ActiveRecord::Base
end

class AddDummyPlatePurposes < ActiveRecord::Migration
  def self.up
    say "Adding dummy plate purposes"
    [
      {
        :name => 'Control Plate Purpose',
        :visible => false,
        :barcode_prefix => BarcodePrefix.find_by_prefix('NT'),
        :type => nil,
        :target_type => nil,
        :can_be_considered_a_stock_plate => true,
        :pulldown_display => nil,
        :default_state => 'pending',
        :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate'),
        :cherrypickable_target => 0,
        :qc_display => 1
      },
      {
        :name => 'Dummy Purpose B',
        :visible => false,
        :barcode_prefix => BarcodePrefix.find_by_prefix('PA'),
        :type => nil,
        :target_type => nil,
        :can_be_considered_a_stock_plate => true,
        :pulldown_display => nil,
        :default_state => 'pending',
        :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate'),
        :cherrypickable_target => 0,
        :qc_display => 1
      },
      {
        :name => 'Dummy Purpose C',
        :visible => false,
        :barcode_prefix => BarcodePrefix.find_by_prefix('DN'),
        :type => 'PicoAssayPlatePurpose',
        :target_type => nil,
        :can_be_considered_a_stock_plate => false,
        :pulldown_display => nil,
        :default_state => 'pending',
        :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate'),
        :cherrypickable_target => 0,
        :qc_display => 1
      },
      {
        :name => 'Dummy Purpose D',
        :visible => false,
        :barcode_prefix => BarcodePrefix.find_by_prefix('DN'),
        :type => 'DilutionPlatePurpose',
        :target_type => 'DilutionPlate',
        :can_be_considered_a_stock_plate => false,
        :pulldown_display => nil,
        :default_state => 'pending',
        :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate'),
        :cherrypickable_target => 0,
        :qc_display => 0
      },
      {
        :name => 'Dummy Purpose E',
        :visible => false,
        :barcode_prefix => BarcodePrefix.find_by_prefix('GD'),
        :type => nil,
        :target_type => nil,
        :can_be_considered_a_stock_plate => true,
        :pulldown_display => nil,
        :default_state => 'pending',
        :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate'),
        :cherrypickable_target => 0,
        :qc_display => 1
      }
    ].each do |atts|
      PlatePurpose.create!(atts)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ['Control Plate Purpose','Dummy Purpose B','Dummy Purpose C','Dummy Purpose D','Dummy Purpose E'].each do |name|
        PlatePurpose.find_by_name(name).destroy
      end
    end
  end
end
