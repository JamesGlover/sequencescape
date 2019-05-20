# frozen_string_literal: true

module SequencescapeExcel
  ##
  # NullRange
  class NullRange
    ##
    # Always returns A1:A10.
    def reference
      'A1:A10'
    end

    ##
    # Always returns worksheet1!A1:A10
    def absolute_reference
      "worksheet1!#{reference}"
    end

    def ==(other)
      other.is_a?(self.class)
    end
  end
end
