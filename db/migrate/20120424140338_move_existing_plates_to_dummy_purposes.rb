class PlatePurposes < ActiveRecord::Base
  belongs_to :barcode_printer_type
  belongs_to :barcode_prefix
end

class BarcodePrinterType < ActiveRecord::Base
end

class BarcodePrefix < ActiveRecord::Base
end

class MoveExistingPlatesToDummyPurposes < ActiveRecord::Migration

  @purposes = [
    {
      :name => 'Dummy Purpose A',
      :sti_type => 'ControlPlate',
      :plate_purpose_id => PlatePurpose.find_by_name('Stock Plate'),
      :barcode_prefix_id => BarcodePrefix.find_by_prefix('NT').id
    },
    {
      :name => 'Dummy Purpose B',
      :sti_type => 'PicoAssayAPlate',
      :plate_purpose_id => PlatePurpose.find_by_name('Stock Plate'),
      :barcode_prefix_id => BarcodePrefix.find_by_prefix('PA').id
    },
    {
      :name => 'Dummy Purpose C',
      :sti_type => 'Plate',
      :plate_purpose_id => PlatePurpose.find_by_name('Pico Assay Plates'),
      :barcode_prefix_id => BarcodePrefix.find_by_prefix('DN').id
    },
    {
      :name => 'Dummy Purpose D',
      :sti_type => 'Plate',
      :plate_purpose_id => PlatePurpose.find_by_name('Working Dilution'),
      :barcode_prefix_id => BarcodePrefix.find_by_prefix('NT').id
    }
  ]

  def self.up
    ActiveRecord::Base.transaction do
      @purposes.each do |r|
        say "Replacing with #{r[:name]}."
        Plate.update_all(
          {:plate_purpose_id => PlatePurpose.find_by_name(r[:name]).id},
          [
            "sti_type = ? AND plate_purpose_id = ? AND barcode_prefix_id = ?",
            'r[:sti_type]','r[:plate_purpose_id]','r[:barcode_prefix_id]'])
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      @purposes.each do |r|
        say "Replacing #{r[:name]}."
        Plate.update_all(
          {:plate_purpose_id => r[:plate_purpose_id]},
          ["plate_purpose_id = ?", PlatePurpose.find_by_name(r[:name]).id])
      end
    end
  end

end
