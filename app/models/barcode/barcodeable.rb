# frozen_string_literal: true

# Anything that has a barcode is considered barcodeable.
module Barcode::Barcodeable
  def self.included(base)
    base.class_eval do
      # Default prefix is the fallback prefix if no purpose is available.
      class_attribute :default_prefix
      before_create :set_default_prefix

      has_one :primary_barcode, -> { order(id: :desc) }, foreign_key: :asset_id, inverse_of: :asset, dependent: :destroy, class_name: 'Barcode'

      delegate :ean13_barcode, :machine_barcode, :human_barcode, to: :primary_barcode, allow_nil: true
    end
  end

  def generate_barcode
    self.barcode = AssetBarcode.new_barcode
  end

  def barcode_number
    primary_barcode&.number&.to_s
  end

  def barcode_format
    primary_barcode.format
  end

  def set_default_prefix
    return if primary_barcode.present?
    self.barcode_prefix = purpose&.barcode_prefix || BarcodePrefix.find_or_create_by(prefix: default_prefix)
  end
  private :set_default_prefix

  def prefix
    primary_barcode.barcode_prefix
  end

  def sanger_human_barcode
    human_barcode
  end

  def barcode_summary
    {
      type: barcode_type,
      two_dimensional: two_dimensional_barcode
    }.merge(primary_barcode.summary)
  end

  #  deprecate sanger_human_barcode: 'use #human_barcode instead'

  # def ean13_barcode
  #   return nil unless barcode.present? and prefix.present?
  #   Barcode.calculate_barcode(prefix, barcode.to_i).to_s
  # end
  # alias_method :machine_barcode, :ean13_barcode

  def role
    return nil if no_role?
    stock_plate.wells.first.requests.first.role
  end

  def no_role?
    if stock_plate.nil?
      true
    elsif stock_plate.wells.first.nil?
      true
    elsif stock_plate.wells.first.requests.first.nil?
      true
    else
      false
    end
  end

  def external_identifier
    sanger_human_barcode
  end

  def printable_target
    self
  end

  def barcode!
    barcode
  end

  # TODO: Deprecate once tests are passing. Then fix usage.
  def barcode=(barcode)
    @barcode_number ||= barcode
    build_barcode_when_complete
  end

  def barcode_prefix=(barcode_prefix)
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
