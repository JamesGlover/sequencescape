class MovePlatePurposeToPlateMetadata < ActiveRecord::Migration
  @default_id = PlatePurpose.default.id

  def self.up
    ActiveRecord::Base.transaction do
      say "Moving plate_purpose data to plate_metadata table"
      connection.execute <<-SQLQUERY
        UPDATE assets AS a
        LEFT OUTER JOIN plate_metadata AS pm
        ON a.id = pm.plate_id
          SET pm.plate_purpose_id = IFNULL(a.plate_purpose_id,#{@default_id})
        WHERE a.sti_type In ('Plate','PicoAssayAPlate','PicoAssayPlate','PicoAssayBPlate','PicoDilutionPlate','WorkingDilutionPlate','GelDilutionPlate','SequenomQCPlate','PlateTemplate', 'ControlPlate','PulldownPlate','PulldownAliquotPlate','PulldownEnrichmentOnePlate','PulldownEnrichmentTwoPlate','PulldownEnrichmentThreePlate','PulldownEnrichmentFourPlate','PulldownPcrPlate','PulldownQpcrPlate','PulldownRunOfRobotPlate','PulldownSequenceCapture', 'PulldownSonicationPlate','DilutionPlate');
      SQLQUERY

    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      say "Moving plate_purpose data to assets table"
      connection.execute <<-SQLQUERY
        UPDATE assets AS a
        LEFT OUTER JOIN plate_metadata AS pm
        ON a.id = pm.plate_id
        SET a.plate_purpose_id = pm.plate_purpose_id
        WHERE a.sti_type In ('Plate','PicoAssayAPlate','PicoAssayPlate','PicoAssayBPlate','PicoDilutionPlate','WorkingDilutionPlate','GelDilutionPlate','SequenomQCPlate','PlateTemplate', 'ControlPlate','PulldownPlate','PulldownAliquotPlate','PulldownEnrichmentOnePlate','PulldownEnrichmentTwoPlate','PulldownEnrichmentThreePlate','PulldownEnrichmentFourPlate','PulldownPcrPlate','PulldownQpcrPlate','PulldownRunOfRobotPlate','PulldownSequenceCapture', 'PulldownSonicationPlate','DilutionPlate')
        AND pm.plate_purpose_id != 0;
      SQLQUERY
    end
  end

end
