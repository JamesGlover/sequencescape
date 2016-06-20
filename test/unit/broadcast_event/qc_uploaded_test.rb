#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2016 Genome Research Ltd.
require './test/test_helper'
require 'csv'


class QcUploadedTest < ActiveSupport::TestCase

  context "BroadcastEvent::QcUploadedTest" do

    context "With a valid csv file" do
      setup do
        @qc_file = create :qc_file, filename: 'example.csv', uploaded_data:{file:"",filename:'example.csv'}
        @plate = @qc_file.asset
        @sample = @plate.wells.first.aliquots.first.sample
        @study = @plate.wells.first.aliquots.first.study
        @project = @plate.wells.first.aliquots.first.project
        @event = BroadcastEvent::QcUploaded.create!(seed:@qc_file)
      end

      should "render the expected message" do
        assert @event.to_json
        subject_map = @event.subjects.map {|s| [s.role_type,s.target] }
        assert subject_map.include?(['labware',@plate]), "Could not find plate in #{subject_map}"
        assert subject_map.include?(['qc_file',@qc_file]), "Could not find qc_file in #{subject_map}"
        assert subject_map.include?(['sample',@sample]), "Could not find sample #{@sample} in #{subject_map}"
        assert subject_map.include?(['study',@study]), "Could not find study in #{subject_map}"
        assert subject_map.include?(['project',@project]), "Could not find project in #{subject_map}"
        assert_equal({'file_type'=>'UNKNOWN'}, @event.metadata)
      end
    end
  end
end
