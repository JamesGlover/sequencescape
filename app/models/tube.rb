class Tube < Aliquot::Receptacle
  include LocationAssociation::Locatable
  include Barcode::Barcodeable
  include Tag::Associations

  named_scope :include_scanned_into_lab_event, :include => :scanned_into_lab_event

  # The type of the printer that should be used for tubes is the 1D tube printer.
  def self.barcode_type
    return @barcode_type if @barcode_type.present?
    barcode_printer_for_1d_tubes = BarcodePrinterType.find_by_name('1D Tube') or raise StandardError, 'Cannot find 1D tube printer'
    @barcode_type = barcode_printer_for_1d_tubes.printer_type_id
  end

  delegate :barcode_type, :to => 'self.class'

  named_scope :with_machine_barcode, lambda { |*barcodes|
    query_details = barcodes.flatten.map do |source_barcode|
      barcode_number = Barcode.number_to_human(source_barcode)
      prefix_string  = Barcode.prefix_from_barcode(source_barcode)
      barcode_prefix = BarcodePrefix.find_by_prefix(prefix_string)

      if barcode_number.nil? or prefix_string.nil? or barcode_prefix.nil?
        { :query => 'FALSE' }
      else
        { :query => '(barcode=? AND barcode_prefix_id=?)', :conditions => [ barcode_number, barcode_prefix.id ] }
      end
    end.inject({ :query => [], :conditions => [] }) do |building, current|
      building.tap do
        building[:query]      << current[:query]
        building[:conditions] << current[:conditions]
      end
    end

    { :conditions => [ query_details[:query].join(' OR '), *query_details[:conditions].flatten.compact ] }
  }

  def self.find_from_machine_barcode(source_barcode)
    with_machine_barcode(source_barcode).first
  end

  def name_for_label
    (primary_aliquot.nil? or primary_aliquot.sample.sanger_sample_id.blank?) ? self.name : primary_aliquot.sample.shorten_sanger_sample_id
  end
end
