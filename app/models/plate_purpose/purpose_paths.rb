module PlatePurpose::PurposePaths
  def gel_dilution
    @gel_dilution ||= find( :first, {:conditions => ["name = ?", "Gel Dilution"]} )
  end
  def working_dilution
    @working_dilution ||= find(:first, {:conditions => ["name = ?", "Working Dilution"]})
  end
  def pulldown_aliquot
    @pulldown_aliquot ||= find(:first, {:conditions => ["name = ?", "Pulldown Aliquot"]})
  end
  def pulldown_sonication
    @pulldown_sonication ||= find(:first, {:conditions => ["name = ?", "Sonication"]})
  end
  def pulldown_run_of_robot
    @pulldown_run_of_robot ||= find(:first, {:conditions => ["name = ?", "Run Of Robot"]})
  end
  def pulldown_enrichment_one
    @pulldown_enrichment_one  ||= find(:first, {:conditions => ["name = ?", "EnRichment 1"]})
  end
  def pulldown_enrichment_two
    @pulldown_enrichment_two ||= find(:first, {:conditions => ["name = ?", "EnRichment 2"]})
  end
  def pulldown_enrichment_three
    @pulldown_enrichment_three ||= find(:first, {:conditions => ["name = ?", "EnRichment 3"]})
  end
  def pulldown_enrichment_four
    @pulldown_enrichment_four ||= find(:first, {:conditions => ["name = ?", "EnRichment 4"]})
  end
  def pulldown_sequence_capture
    @pulldown_sequence_capture ||= find(:first, {:conditions => ["name = ?", "Sequence Capture"]})
  end
  def pulldown_pcr
    @pulldown_pcr ||= find(:first, {:conditions => ["name = ?", "Pulldown PCR"]})
  end
  def pulldown_qpcr
    @pulldown_qpcr ||= find(:first, {:conditions => ["name = ?", "Pulldown qPCR"]})
  end
  def pico_assay_a
    @pico_assay_a ||= find(:first, {:conditions => ["name = ?", "Pico Assay A"]})
  end
  def pico_dilution
    @pico_dilution ||= find(:first, {:conditions => ["name = ?", "Pico Dilution"]})
  end
  def sequenom
    @sequenom ||= find(:first, {:conditions => ["name = ?", "Sequenom"]})
  end
  def stock_plate
    @stock_plate ||= find(:first, {:conditions => ["name = ?", "Stock Plate"]})
  end
  alias :default :stock_plate
  def legacy_pulldown
    @legacy_pulldown ||= find(:first, {:conditions => ["name = ?", "Legacy Pulldown Intermediate"]})
  end
end