#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
require "test_helper"
require 'unit/tag_qc/qcable_statemachine_checks'

class QcableTest < ActiveSupport::TestCase
  context "A Qcable" do

    setup do
      PlateBarcode.stubs(:create).returns(OpenStruct.new(:barcode => (Factory.next :barcode)))
    end

    should_belong_to :lot
    should_belong_to :asset
    should_belong_to :qcable_creator

    should_have_one :stamp_qcable
    should_have_one :stamp

    should_validate_presence_of :lot, :asset, :qcable_creator

    should 'not let state be nil' do
      @qcable = Factory :qcable
      @qcable.state = nil
      assert !@qcable.valid?
    end

    context "#qcable" do
      setup do
        @mock_purpose = mock('Purpose')
        @mock_purpose.expects('create!').returns(Asset.new).once
        @mock_lot     = Factory :lot
        @mock_lot.expects(:target_purpose).returns(@mock_purpose).once
      end

      should "create an asset of the given purpose" do
        @qcable       = Factory :qcable, :lot => @mock_lot
      end

    end
  end

end
