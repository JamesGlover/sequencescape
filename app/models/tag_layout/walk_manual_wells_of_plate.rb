class TagLayout::WalkManualWellsOfPlate < TagLayout::Walker # rubocop:todo Style/Documentation
  self.walking_by = 'wells of plate'

  def walk_wells
    wells_in_walking_order.with_aliquots.each_with_index do |well, index|
      yield(well, index) unless well.nil?
    end
  end
end
