
class PlatePurpose < ActiveRecord::Base
  belongs_to :barcode_prefix
end

class BarcodePrefix < ActiveRecord::Base
end

class AddPrefixesToPurposes < ActiveRecord::Migration
   @purposes = [
      {:name =>'Gel Dilution', :prefix => 'GD'},
      {:name =>'Pico Assay A', :prefix => 'PA'},
      {:name =>'Pico Assay B', :prefix => 'PB'},
      {:name =>'Pico Assay Plates', :prefix => 'PA'},
      {:name =>'Pico Dilution', :prefix => 'PD'},
      {:name =>'Pulldown Aliquot', :prefix => 'FA'},
      {:name =>'EnRichment 1', :prefix => 'FG'},
      {:name =>'EnRichment 2', :prefix => 'FI'},
      {:name =>'EnRichment 3', :prefix => 'FK'},
      {:name =>'EnRichment 4', :prefix => 'FM'},
      {:name =>'Pulldown PCR', :prefix => 'FQ'},
      {:name =>'Pulldown qPCR', :prefix => 'FS'},
      {:name =>'Run Of Robot', :prefix => 'FE'},
      {:name =>'Sequence Capture', :prefix => 'FO'},
      {:name =>'Sonication', :prefix => 'FC'},
      {:name =>'Working Dilution', :prefix => 'WD'},
    ]
  def self.up

    ActiveRecord::Base.transaction do
      @purposes.each do |purpose|
        say "Updating #{purpose[:name]} with #{purpose[:prefix]}"
        plate_purpose = PlatePurpose.find_by_name(purpose[:name])
        plate_purpose.barcode_prefix = BarcodePrefix.find_by_prefix(purpose[:prefix])
        plate_purpose.save!
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
          @purposes.each do |purpose|
            plate_purpose = PlatePurpose.find_by_name(purpose[:name])
            plate_purpose.barcode_prefix = nil
            plate_purpose.save!
          end
        end
  end

end
