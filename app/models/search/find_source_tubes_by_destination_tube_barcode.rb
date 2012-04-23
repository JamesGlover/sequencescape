class Search::FindSourceTubesByDestinationTubeBarcode < Search
  def scope(criteria)
    Tube.source_assets_from_machine_barcode(criteria['barcode'])
  end
end
