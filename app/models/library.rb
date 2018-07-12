# frozen_string_literal: true

# A library represents a sample which has been processed for sequencing,
# such as through the application of tags. The library record itself
# is an abstract representation, which gets generated upfront.
class Library < ApplicationRecord
  belongs_to :sample, required: true
  belongs_to :request, required: true
  belongs_to :library_type, required: true

  validates :name, presence: true

  alias legacy_library_id id
end
