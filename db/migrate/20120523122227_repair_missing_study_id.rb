class RepairMissingStudyId < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      s1 = Aliquot.find_all_by_study_id(nil).count
      say "#{s1} aliquots with missing study id"
      say "Repairing wells via sample manifest"
      # Repairs 1536 wells via sample manifest
      # All manifest 695, all samples single study
      execute <<-SQL
       UPDATE `aliquots`
       	JOIN `assets` ON `assets`.id = `aliquots`.receptacle_id
       	JOIN `samples` ON `samples`.id = `aliquots`.sample_id
       	JOIN `sample_manifests` ON `samples`.sample_manifest_id = `sample_manifests`.id
       	SET `aliquots`.study_id = `sample_manifests`.study_id
       WHERE `aliquots`.study_id IS NULL AND sti_type = 'Well';
      SQL
      # Checked
      s2 = Aliquot.find_all_by_study_id(nil).count
      say "#{s1-s2} repaired in previous step, #{s2} remaining"
      #We'll keep it all in a single transactio

      say "Repairing via create asset request"
      # All samples in 1 study only

      execute <<-SQL
       UPDATE `aliquots`
       	INNER JOIN `assets` ON `assets`.id = `aliquots`.receptacle_id
      	LEFT OUTER JOIN `requests` ON `requests`.`asset_id` = `assets`.id
      	SET `aliquots`.study_id = `requests`.initial_study_id
      WHERE `aliquots`.study_id IS NULL AND `assets`.sti_type = 'SampleTube' AND `requests`.initial_study_id IS NOT NULL AND `requests`.sti_type='CreateAssetRequest';
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
      WHERE `aliquots`.study_id IS NULL AND sti_type = 'SampleTube' AND `study_samples`.study_id IS NULL
      	AND `asset_group_assets`.asset_group_id IS NOT NULL;
      SQL
      s4 = Aliquot.find_all_by_study_id(nil).count
      say "#{s3-s4} repaired in previous step, #{s4} remaining"

      say "Manually repairing 1 entrt"
      a = Aliquot.find_by_id(4061334)
      a.update_attributes!(:study_id => 1980) unless a.nil?
      s5 = Aliquot.find_all_by_study_id(nil).count
      say "#{s4-s5} repaired in previous step, #{s5} remaining"

    end
  end

  def self.down
  end
end
