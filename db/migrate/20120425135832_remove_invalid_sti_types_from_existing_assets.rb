class RemoveInvalidStiTypesFromExistingAssets < ActiveRecord::Migration
  @sti_types = [
    ["WorkingDilutionPlate",PlatePurpose.find_by_name('Working Dilution').id, "DilutionPlate"],
    ["PicoAssayAPlate",PlatePurpose.find_by_name('Pico Assay A').id,"PicoAssayPlate"],
    ["PicoAssayBPlate",PlatePurpose.find_by_name('Pico Assay B').id,"PicoAssayPlate"],
    ["GelDilutionPlate",PlatePurpose.find_by_name('Gel Dilution').id,"DilutionPlate"],
    ["PulldownAliquotPlate",PlatePurpose.find_by_name('Pulldown Aliquot').id,"PulldownPlate"],
    ["PulldownEnrichmentOnePlate",PlatePurpose.find_by_name('EnRichment 1').id,"PulldownPlate"],
    ["PulldownEnrichmentTwoPlate",PlatePurpose.find_by_name('EnRichment 2').id,"PulldownPlate"],
    ["PulldownEnrichmentThreePlate",PlatePurpose.find_by_name('EnRichment 3').id,"PulldownPlate"],
    ["PulldownEnrichmentFourPlate",PlatePurpose.find_by_name('EnRichment 4').id,"PulldownPlate"],
    ["PulldownPcrPlate",PlatePurpose.find_by_name('Pulldown PCR').id,"PulldownPlate"],
    ["PulldownQpcrPlate",PlatePurpose.find_by_name('Pulldown qPCR').id,"PulldownPlate"],
    ["PulldownRunOfRobotPlate",PlatePurpose.find_by_name('Run Of Robot').id,"PulldownPlate"],
    ["PulldownSequenceCapturePlate",PlatePurpose.find_by_name('Sequence Capture').id,"PulldownPlate"],
    ["PulldownSonnicationPlate",PlatePurpose.find_by_name('Sonication').id,"PulldownPlate"]
  ]
  def self.up
    ActiveRecord::Base.transaction do
      @sti_types.each do |type|
        Asset.update_all({:sti_type => type.last },["sti_type = ?",type.first])
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      @sti_types.each do |type|
        Asset.update_all({:sti_type => type.first },["sti_type = ? AND plate_purpose_id = ?",type.last, type[1]])
      end
      say 'Reverting custom plates'
      Asset.update_all({:sti_type => 'GelDilutionPlate'}, ["sti_type = ? AND plate_purpose_id = ?", 'DilutionPlate', PlatePurpose.find_by_name('Dummy Purpose E').id])
      Asset.update_all({:sti_type => 'PicoAssayAPlate'}, ["sti_type = ? AND plate_purpose_id = ?", 'PicoAssayPlate', PlatePurpose.find_by_name('Dummy Purpose B').id])
    end

  end
end
