class ConvertSampleMetadataToUtf8 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      execute("ALTER DATABASE #{ActiveRecord::Base.connection.current_database} CHARACTER SET utf8 COLLATE utf8_unicode_ci;")
      each_table do |table_name, transcode|
        execute("ALTER TABLE #{table_name} #{transcode} utf8 COLLATE utf8_unicode_ci;")
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      execute("ALTER DATABASE #{ActiveRecord::Base.connection.current_database} CHARACTER SET latin1 COLLATE latin1_swedish_ci;")
      each_table do |table_name, transcode|
        execute("ALTER TABLE #{table_name} #{transcode} latin1 COLLATE latin1_swedish_ci;")
      end
    end
  end

  def self.each_table
    ActiveRecord::Base.connection.tables.each {|t|
      yield (t,transcode?(t)) unless excluded?(t)
     }
  end

  def self.transcode?(table)
    ['uuids', 'aliquots','asset_group_assets','asset_links',
      'batch_requests','container_associations','db_files',
      'db_files_shadow', 'identifiers', 'location_associations',
      'plate_metadata', 'request_quotas','requests', 'study_smaples',
      'study_samples_backup', 'submitted_assets','tag_layouts','tags',
      'tube_creation_children','well_links','well_to_tube_transfers'].include?(table) ? "CHARACTER SET" : "CONVERT TO CHARACTER SET"
  end
  # Also add: 'events'?, 'well_attributes'

  # 'study_reports_shadow', 'sample_manifests_shadow (20m in total)'

  def self.excluded?(table)
   [].include?(table)
  end

end
