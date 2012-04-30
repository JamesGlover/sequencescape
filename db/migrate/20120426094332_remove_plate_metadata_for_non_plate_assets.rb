class RemovePlateMetadataForNonPlateAssets < ActiveRecord::Migration
  def self.up
    say "Removing redundant plate metadata from non-plate Assets."
    ActiveRecord::Base.transaction do
      connection.execute <<-SQLQUERY
      DELETE pm
      FROM plate_metadata AS pm
      INNER JOIN assets AS a
      ON a.id = pm.plate_id
      WHERE NOT a.sti_type In ('Plate','PicoAssayAPlate','PicoAssayPlate','PicoAssayBPlate','PicoDilutionPlate','WorkingDilutionPlate','GelDilutionPlate','SequenomQCPlate','PlateTemplate', 'ControlPlate','PulldownPlate','PulldownAliquotPlate','PulldownEnrichmentOnePlate','PulldownEnrichmentTwoPlate','PulldownEnrichmentThreePlate','PulldownEnrichmentFourPlate','PulldownPcrPlate','PulldownQpcrPlate','PulldownRunOfRobotPlate','PulldownSequenceCapture', 'PulldownSonicationPlate','DilutionPlate')
      AND pm.infinium_barcode IS NULL;
      DELETE pm FROM plate_metadata pm
      LEFT OUTER JOIN assets a
      ON pm.plate_id = a.id
      WHERE a.id IS NULL;
      SQLQUERY
    end
  end

  def self.down
    say "This transaction is destructive and can not be reversed."
    riase ActiveRecord::IrreversibleMigration
  end
end
