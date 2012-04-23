class Search::FindTubeByBarcode < Search
  def scope(criteria)
    Tube.with_machine_barcode(criteria['barcode'])
  end
end
