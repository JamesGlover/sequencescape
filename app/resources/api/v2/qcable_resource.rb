# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Qcable
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class QcableResource < BaseResource
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_one :lot
      has_one :asset

      # Attributes
      attribute :uuid, readonly: true
      attribute :state, readonly: true

      # Filters
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
