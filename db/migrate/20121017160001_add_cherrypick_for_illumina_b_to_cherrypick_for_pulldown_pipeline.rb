#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddCherrypickForIlluminaBToCherrypickForPulldownPipeline < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      cherrypick_for_illumina_b  = RequestType.find_by_key('cherrypick_for_illumina_b')
      cherrypicking_for_pulldown = Pipeline.find_by_name('Cherrypicking for Pulldown')

      cherrypicking_for_pulldown.request_types << cherrypick_for_illumina_b
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      cherrypicking_for_pulldown = Pipeline.find_by_name('Cherrypicking for Pulldown')
      cherrypicking_for_pulldown.pipelines_request_types.detect {|prt| prt.request_type.key == 'cherrypick_for_illumina_b'}.destroy
    end
  end

end
