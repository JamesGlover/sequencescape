class Search::FindSourcePlatesByDestinationPlateBarcode < Search
  def scope(criteria)
    Plate.source_assets_from_machine_barcode(criteria['barcode'])
  end
end
