class AddPulldownIntermediates < ActiveRecord::Migration
  def self.up
    PlatePurpose.create!(
      :name => "Legacy Pulldown Intermediate",
      :visible => true,
      :barcode_prefix => BarcodePrefix.find_by_prefix('DN'),
      :type => nil,
      :target_type => 'Plate',
      :can_be_considered_a_stock_plate => true,
      :pulldown_display => nil,
      :default_state => 'pending',
      :barcode_printer_type => BarcodePrinterType.find_by_type('BarcodePrinterType96Plate'),
      :cherrypickable_target => 0,
      :qc_display => 1
    )
  end

  def self.down
    PlatePurpose.find_by_name("Legacy Pulldown Intermediate").destroy
  end
end
