# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class LabwareTest < ActiveSupport::TestCase
  context 'Labware' do
    context 'with a barcode' do
      setup do
        @labware = create :labware
        @result_hash = @labware.barcode_and_created_at_hash
      end
      should 'return a hash with the barcode and created_at time' do
        assert !@result_hash.blank?
        assert @result_hash.is_a?(Hash)
        assert @result_hash[:barcode].is_a?(String)
        assert @result_hash[:created_at].is_a?(ActiveSupport::TimeWithZone)
      end
    end

    context 'without a barcode' do
      setup do
        @labware = create :labware, barcode: nil
        @result_hash = @labware.barcode_and_created_at_hash
      end
      should 'return an empty hash' do
        assert @result_hash.blank?
      end
    end

    context '#scanned_in_date' do
      setup do
        @scanned_in_labware = create :labware
        @unscanned_in_labware = create :labware
        @scanned_in_event = create :event, content: Date.today.to_s, message: 'scanned in', family: 'scanned_into_lab', eventful: @scanned_in_labware
      end
      should 'return a date if it has been scanned in' do
        assert_equal Date.today.to_s, @scanned_in_labware.scanned_in_date
      end

      should "return nothing if it hasn't been scanned in" do
        assert @unscanned_in_labware.scanned_in_date.blank?
      end
    end
  end

  context '#assign_relationships' do
    context 'with the correct arguments' do
      setup do
        @labware = create :labware
        @parent_labware_1 = create :labware
        @parent_labware_2 = create :labware
        @parents = [@parent_labware_1, @parent_labware_2]
        @child_labware = create :labware

        @labware.assign_relationships(@parents, @child_labware)
      end

      should 'add 2 parents to the labware' do
        assert_equal 2, @labware.reload.parents.size
      end

      should 'add 1 child to the labware' do
        assert_equal 1, @labware.reload.children.size
      end

      should 'set the correct child' do
        assert_equal @child_labware, @labware.reload.children.first
      end

      should 'set the correct parents' do
        assert_equal @parents, @labware.reload.parents
      end
    end

    context 'with the wrong arguments' do
      setup do
        @labware = create :labware
        @parent_labware_1 = create :labware
        @parent_labware_2 = create :labware
        @labware.parents = [@parent_labware_1, @parent_labware_2]
        @parents = [@parent_labware_1, @parent_labware_2]
        @labware.reload
        @child_labware = create :labware

        @labware.assign_relationships(@labware.parents, @child_labware)
      end

      should 'add 2 parents to the labware' do
        assert_equal 2, @labware.reload.parents.size
      end

      should 'add 1 child to the labware' do
        assert_equal 1, @labware.reload.children.size
      end

      should 'set the correct child' do
        assert_equal @child_labware, @labware.reload.children.first
      end

      should 'set the correct parents' do
        assert_equal @parents, @labware.reload.parents
      end
    end
  end
end
