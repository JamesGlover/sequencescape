# frozen_string_literal: true

# A library represents a sample which has been processed for sequencing,
# such as through the application of tags. The library record itself
# is an abstract representation, which gets generated upfront.
class Library < ApplicationRecord
  include Uuid::Uuidable

  belongs_to :sample, required: true
  belongs_to :request, required: true
  belongs_to :library_type, required: true
  # Tracks when one library has been derived from another
  belongs_to :parent_library, class_name: 'Library', required: false

  validates :name, presence: true, uniqueness: true
  before_validation :generate_library_name, unless: :name?
  before_validation :extract_sample_from_parent_library, unless: :sample

  alias legacy_library_id id
  alias_attribute :external_identifier, :name

  # Strips the request_id off the library name
  def base_name
    name&.gsub(/#\d+\z/, '')
  end

  def extract_sample_from_parent_library
    self.sample = parent_library&.sample
  end

  # Derived libraries follow the same name format as their parent,
  # with the id updated with the new request_id.
  # New libraries derive their name from the display name of the asset.
  def generate_library_name
    new_base_name = parent_library ? parent_library.base_name : request.asset.external_identifier
    self.name = "#{new_base_name}##{request_id}"
  end
end
