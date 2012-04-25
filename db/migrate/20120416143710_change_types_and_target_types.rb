class ChangeTypesAndTargetTypes < ActiveRecord::Migration
  def self.up
    @replacements = {
      :target_type => {
        'PulldownPlate' => [
          'PulldownAliquotPlate',        'PulldownSonicationPlate',
          'PulldownRunOfRobotPlate',     'PulldownEnrichmentOnePlate',
          'PulldownEnrichmentTwoPlate',  'PulldownEnrichmentThreePlate',
          'PulldownEnrichmentFourPlate', 'PulldownSequenceCapturePlate',
          'PulldownPcrPlate',            'PulldownQpcrPlate'
        ],
        'DilutionPlate' => [
          'WorkingDilutionPlate', 'GelDilutionPlate'
        ]
      }
    }
    ActiveRecord::Base.transaction do
      @replacements.each do |k,v|
        v.each do |nu,old|
          PlatePurpose.update_all({k => nu}, {k => old})
        end
      end
    end
  end

  def self.down
    @originals = [
      {:name =>'Gel Dilution', :target_type => 'GelDilutionPlate'},
      {:name =>'Gel Dilution Plates', :target_type => nil},
      {:name =>'Pico Assay A', :target_type => 'PicoAssayAPlate'},
      {:name =>'Pico Assay B', :target_type => 'PicoAssayBPlate'},
      {:name =>'Pico Assay Plates', :target_type => nil},
      {:name =>'Pulldown Aliquot', :target_type => 'PulldownAliquotPlate'},
      {:name =>'EnRichment 1', :target_type => 'PulldownEnrichmentOnePlate'},
      {:name =>'EnRichment 2', :target_type => 'PulldownEnrichmentTwoPlate'},
      {:name =>'EnRichment 3', :target_type => 'PulldownEnrichmentThreePlate'},
      {:name =>'EnRichment 4', :target_type => 'PulldownEnrichmentFourPlate'},
      {:name =>'Pulldown PCR', :target_type => 'PulldownPcrPlate'},
      {:name =>'Pulldown qPCR', :target_type => 'PulldownQpcrPlate'},
      {:name =>'Run Of Robot', :target_type => 'PulldownRunOfRobotPlate'},
      {:name =>'Sequence Capture', :target_type => 'PulldownSequenceCapturePlate'},
      {:name =>'Sonication', :target_type => 'PulldownSonicationPlate'},
      {:name =>'Working Dilution', :target_type => 'WorkingDilutionPlate'}
    ]
    ActiveRecord::Base.transaction do
      @originals.each do |purpose|
        plate = PlatePurpose.find_by_name(purpose[:name])
        #plate.update_attribute(:type, purpose[:type])
        plate.update_attribute(:target_type, purpose[:target_type])

      end
    end
  end
end
