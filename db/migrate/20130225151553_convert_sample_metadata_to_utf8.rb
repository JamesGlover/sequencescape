class ConvertSampleMetadataToUtf8 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      execute('ALTER TABLE sample_metadata CONVERT TO CHARACTER SET utf8 COLLATE utf8_unicode_ci;')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      execute('ALTER TABLE sample_metadata CONVERT TO CHARACTER SET latin1 COLLATE latin1_swedish_ci;')
    end
  end
end
