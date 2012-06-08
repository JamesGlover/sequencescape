class RepairMissingStudyId < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      s1 = Aliquot.find_all_by_study_id(nil).count
      say "#{s1} aliquots with missing study id"

      say "Repairing via create asset request"
      execute <<-SQL
       UPDATE `aliquots`
       	INNER JOIN `assets` ON `assets`.id = `aliquots`.receptacle_id
      	LEFT OUTER JOIN `requests` ON `requests`.`asset_id` = `assets`.id
      	SET `aliquots`.study_id = `requests`.initial_study_id
      WHERE `aliquots`.study_id IS NULL AND `requests`.initial_study_id IS NOT NULL AND `requests`.sti_type='CreateAssetRequest';
      SQL

      # Checked
      s2 = Aliquot.find_all_by_study_id(nil).count
      say "#{s1-s2} repaired in previous step, #{s2} remaining"

      say "Repairing wells via sample manifest"
      execute <<-SQL
       UPDATE `aliquots`
       	JOIN `assets` ON `assets`.id = `aliquots`.receptacle_id
       	JOIN `samples` ON `samples`.id = `aliquots`.sample_id
       	JOIN `sample_manifests` ON `samples`.sample_manifest_id = `sample_manifests`.id
       	SET `aliquots`.study_id = `sample_manifests`.study_id
       WHERE `aliquots`.study_id IS NULL AND sti_type = 'Well';
      SQL

      s3 = Aliquot.find_all_by_study_id(nil).count
      say "#{s2-s3} repaired in previous step, #{s3} remaining"

      say "Repairing via asset group"
      execute <<-SQL
       UPDATE `aliquots`
       	INNER JOIN `assets` ON `assets`.id = `aliquots`.receptacle_id
      	JOIN `samples` ON `samples`.id = `aliquots`.sample_id
      	LEFT OUTER JOIN `sample_manifests` ON `samples`.sample_manifest_id = `sample_manifests`.id
      	LEFT OUTER JOIN `study_samples` ON `samples`.id = `study_samples`.sample_id
      	LEFT OUTER JOIN `asset_group_assets` ON `assets`.id = `asset_group_assets`.asset_id
      	LEFT OUTER JOIN `asset_groups` ON `asset_group_assets`.asset_group_id = `asset_groups`.id
      	SET `aliquots`.study_id = `asset_groups`.study_id
      WHERE `aliquots`.study_id IS NULL AND (sti_type = 'SampleTube' OR sti_type = 'Well') AND `study_samples`.study_id IS NULL
      	AND `asset_group_assets`.asset_group_id IS NOT NULL;
      SQL
      s4 = Aliquot.find_all_by_study_id(nil).count
      say "#{s3-s4} repaired in previous step, #{s4} remaining"



    end
  end

  def self.down
  end
end
