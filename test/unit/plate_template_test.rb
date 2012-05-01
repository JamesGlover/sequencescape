require "test_helper"

class PlateTemplateTest < ActiveSupport::TestCase

  context "A plate template" do
    [1,0,"1","0"].each_with_index do |i,index|
      context "with a control well set to #{i} - #{index}" do
        setup do
          @template = Factory :plate_template
          @template.set_control_well(i)
        end

        should "be saved" do
          assert_equal [], @template.wells
          assert_equal([true,false,true,false][index],@template.control_well?)
        end
      end
    end
    context "with a control well set to 0" do
      setup do
        @template = Factory :plate_template
        @template.set_control_well(0)
      end

      should "return boolean" do
        assert_equal false, @template.control_well?
      end
    end

    context "with a control well set to 1" do
      setup do
        @template = Factory :plate_template
        @template.set_control_well(1)
      end

      should "return boolean" do
        assert @template.control_well?
      end
    end

    context "with no empty wells" do
      setup do
        @template = Factory :plate_template
        @old_wells = Well.count
        @old_asset_link = AssetLink.count
        @template.update_params!(:name=> "a", :value=>"2", :wells => {})
      end
      should "be not add anything" do
        assert_equal @old_wells, Well.count
        assert_equal @old_asset_link, AssetLink.count
      end
    end

    context "with 1 empty well" do
      setup do
        @template = Factory :plate_template
        @old_wells = Well.count
        @template.update_params!(:name=> "a", :value=>"2", :wells => {"A1" => "123"})
      end
      should "not be added" do
        assert_equal @old_wells, Well.count
        assert_equal([123],@template.wells)
      end
    end

    context "with 2 empty wells" do
      setup do
        @template = Factory :plate_template
        @old_wells = Well.count
        @old_asset_link = AssetLink.count
        @template.update_params!(:name=> "a", :value=>"2", :wells => {"A1" => "123","B3"=>"345"})
      end
      should "not be added" do
        assert_equal @old_wells, Well.count
        assert_equal([123,345],@template.wells)
      end
    end

  end
end
