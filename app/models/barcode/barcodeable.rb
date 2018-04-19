# frozen_string_literal: true

# Anything that has a barcode is considered barcodeable.
module Barcode::Barcodeable
  def self.included(base)
    base.class_eval do
      # Default prefix is the fallback prefix if no purpose is available.
      class_attribute :default_prefix

      has_one :primary_barcode, -> { order(id: :desc) }, foreign_key: :asset_id, inverse_of: :asset, dependent: :destroy, class_name: 'Barcode'

      delegate :ean13_barcode, :machine_barcode, :human_barcode, to: :primary_barcode, allow_nil: true
    end
  end

  def generate_barcode
    self.sanger_barcode = { prefix: default_prefix, number: AssetBarcode.new_barcode } unless primary_barcode
  end

  def barcode_number
    primary_barcode&.number&.to_s
  end

  def barcode_format
    primary_barcode.format
  end

  def prefix
    primary_barcode&.barcode_prefix
  end

  def barcode_summary
    {
      type: barcode_type,
      two_dimensional: two_dimensional_barcode
    }.merge(primary_barcode.try(:summary) || {})
  end

  def external_identifier
    human_barcode
  end

  def printable_target
    self
  end

  def sanger_barcode
    barcodes.detect(&:sanger_ean13?)
  end

  def sanger_barcode=(attributes)
    self.primary_barcode = Barcode.build_sanger_ean13(attributes)
    # We've effectively modified the barcodes relationship, so lets reset it.
    # This probably indicates we should handle primary barcode ourself, and load
    # all barcodes whenever.
    barcodes.reset
  end

  deprecate def barcode!
    barcode
  end

  deprecate def barcode=(barcode)
    @barcode_number ||= barcode
    build_barcode_when_complete
  end

  deprecate def barcode_prefix=(barcode_prefix)
    @barcode_prefix ||= barcode_prefix.prefix
    build_barcode_when_complete
  end

  private

  def build_barcode_when_complete
    return unless @barcode_number && @barcode_prefix
    self.primary_barcode = Barcode.build_sanger_ean13(prefix: @barcode_prefix, number: @barcode_number)
    # We've effectively modified the barcodes relationship, so lets reset it.
    # This probably indicates we should handle primary barcode ourself, and load
    # all barcodes whenever.
    barcodes.reset
  end

  def sanger_barcode_object
    @sanger_barcode_object ||= barcodes.find_or_initialize_by(format: :sanger_barcode).handler
  end
end
