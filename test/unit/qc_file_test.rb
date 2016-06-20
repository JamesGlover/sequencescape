#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.

require File.dirname(__FILE__) + '/../test_helper'

class QcFileTest < ActiveSupport::TestCase

  context QcFile do

    context "with an asset" do
      setup do
        @plate = create :plate
        @parser = Object.new
        Parsers.expects(:parser_for).returns(@parser)
      end

      should "uses the parser to update the values of a well" do
        @plate.expects(:update_qc_values_with_parser).with(@parser)
        QcFile.create!(:asset=>@plate)
      end

      should "create a qc_uploaded event" do
        qc_event_count = BroadcastEvent::QcUploaded.count
        @plate.expects(:update_qc_values_with_parser).with(@parser)
        qc_file = QcFile.create!(:asset=>@plate)
        assert_equal 1, BroadcastEvent::QcUploaded.count - qc_event_count
        assert_equal qc_file, BroadcastEvent::QcUploaded.last.seed
      end

    end

      should "have a friendly name" do
        begin
          file = Tempfile.new('example')
          @plate = build :plate
          qc=QcFile.new(:asset=>@plate,:uploaded_data=>{file:file,filename:'example'},filename:'example')
          assert_equal 'example', qc.friendly_name
        ensure
          file.delete
        end
      end
  end

end
