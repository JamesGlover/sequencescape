class Search::FindPlateByBarcode < Search
  def scope(criteria)
    Plate.with_machine_barcode(criteria['barcode'])
  end
end
