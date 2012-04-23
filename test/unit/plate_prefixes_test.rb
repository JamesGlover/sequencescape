require "test_helper"

class PlatePrefixesTest < ActiveSupport::TestCase

  context 'Different plates' do

    setup do
      @all_plates = [
        [Factory(:gel_dilution_plate), 'GD'],
        [Factory(:plate),'DN'],
        [Factory(:control_plate),'DN'],
        [Factory(:dilution_plate),'DN'],
        [Factory(:pico_assay_a_plate),'PA'],
        [Factory(:pico_assay_b_plate),'PB'],
        [Factory(:pico_assay_plate),'PA'],
        [Factory(:pico_dilution_plate),'PD'],
        #[Factory(:sequenom_qc_plate),''],
        [Factory(:working_dilution_plate),'WD']
      ]
    end

    should 'have suitable plate prefixes' do
      @all_plates.each do |plate|
        assert_equal plate[1],plate[0].barcode_prefix.prefix
      end
    end

  end

  context 'Plates created from the class' do

    setup do
      @class_plates = [
        [PlatePurpose.gel_dilution.create!(:barcode=>123456), 'GD'],
        [Plate.create!(:barcode=>123456),'DN'],
        [PlatePurpose.find_by_name('Dilution Plates').create!(:barcode=>123456),'DN'],
        [PlatePurpose.find_by_name('Pico Assay A').create!(:barcode=>123456),'PA'],
        [PlatePurpose.find_by_name('Pico Assay B').create!(:barcode=>123456),'PB'],
        [PlatePurpose.find_by_name('Pico Assay Plates').create!(:barcode=>123456),'PA'],
        [PlatePurpose.find_by_name('Pico Dilution').create!(:barcode=>123456),'PD'],
        #[Factory(:sequenom_qc_plate),''],
        [PlatePurpose.working_dilution.create!(:barcode=>123456),'WD']
      ]
    end

    should 'have suitable plate prefixes' do
      @class_plates.each do |plate|
        assert_equal plate[1],plate[0].barcode_prefix.prefix
      end
    end

  end

end
