module LabelPrinter
  module Label
    class PlateToTubes < BaseTube
      attr_reader :tubes

      def initialize(options)
        @tubes = options[:sample_tubes]
      end

      def top_line(tube)
        tube.name_for_label
      end
    end
  end
end
