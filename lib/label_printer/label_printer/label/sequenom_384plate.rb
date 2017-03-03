module LabelPrinter
  module Label
    class Sequenom384Plate < BasePlate
      attr_reader :plates, :count

      def initialize(options)
        @plates = options[:plates]
        @count = options[:count].to_i
      end

      def create_label(plate)
        super.except(:top_far_right)
      end

      def top_right(plate)
        (plate.label_text_top).to_s
      end

      def bottom_right(plate)
        (plate.label_text_bottom).to_s
      end
    end
  end
end
