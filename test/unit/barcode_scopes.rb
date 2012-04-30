require "test_helper"

class BarcodeScopesTest < ActionController::TestCase
  context "Plate" do
    setup do
      @controller = PlatesController.new
    end

    context "created plates" do
      setup do
        @user = Factory :user, :barcode => 'ID100I'
        @user.is_administrator
        @controller.stubs(:current_user).returns(@user)

        @plate  = Factory :plate, :barcode => "5678"
        @plate2 = Factory :gel_dilution_plate, :barcode => "1234"
      end

      should "be findable by barcode" do
        @plate_array = Plate.with_machine_barcode(Barcode.calculate_barcode(@plate.prefix,5678))
        @plate_array2 = Plate.with_machine_barcode(Barcode.calculate_barcode(@plate2.prefix,1234))
        assert @plate_array.count == 1
        assert @plate_array2.count == 1
      end

    end

  end
end
