# frozen_string_literal: true

# A library represents a sample which has been processed for sequencing,
# such as through the application of tags. The library record itself
# is an abstract representation, which gets generated upfront.
class Library < ApplicationRecord
  include Uuid::Uuidable

  belongs_to :sample, required: true
  belongs_to :request, required: false
  belongs_to :library_type, required: false
  # Tracks when one library has been derived from another
  belongs_to :parent_library, class_name: 'Library', required: false

  has_one :source_asset, through: :request, source: :asset

  validates :name, presence: true, uniqueness: true
  before_validation :generate_library_name, unless: :name?
  before_validation :extract_sample_from_parent_library, unless: :sample

  # Other attributes
  # delegate_identity [Boolean] Specified on some libraries on the initial import
  #                             where multiple aliquots shared the same library_id
  #                             but different samples or library_types. Allows us
  #                             to maintain the same identifiers in eg. the warehouse
  #                             without hamstringing use of library in the future.

  #
  # An integer identifier representing the library.
  # Libraries in the initial import may delegate their identifier
  # to the parent library, to allow us to avoid changing library ids.
  #
  # @return [Integer] A scheme compatible with the days when the library id was
  #                   just the primary key of the tube/well which was tagged.
  def legacy_library_id
    delegate_identity ? parent_library_id : id
  end

  # TEMPORARY METHOD REMOVE ONCE 20180720100019 has run
  def name
    if super == id.to_s
      Asset.find_by(id: super)&.external_identifier || super
    else
      super
    end
  end

  #
  # A more meaningful identifier that can now be user-specified, but typically
  # will be names after the source asset external identifier (Barcode or barcode+well)
  # followed by the library id. The initial import maintains the original format to
  # avoid renaming libraries. Sadly it is not possible to maintain this format for
  # newer libraries. Again, some libraries in the initial import delegate to their
  # parent for backwards compatibility.
  #
  # @return [String] The library name.
  def external_identifier
    delegate_identity ? parent_library.name : name
  end

  # Strips the request_id off the library name
  def base_name
    name&.gsub(/#\d+\z/, '')
  end

  # If no sample is specified, we extract it from the parent library
  def extract_sample_from_parent_library
    self.sample = parent_library&.sample
  end

  # Derived libraries follow the same name format as their parent,
  # with the id updated with the new request_id.
  # New libraries derive their name from the display name of the asset.
  def generate_library_name
    new_base_name = parent_library ? parent_library.base_name : source_asset&.external_identifier
    return if new_base_name.blank?
    self.name = "#{new_base_name}##{request_id}"
  end
end
