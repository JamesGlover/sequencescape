# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of receptacle
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class WellResource < BaseResource
      # Constants...

      immutable # comment to make the resource mutable

      default_includes :uuid_object, :map, :transfer_requests_as_target, plate: :barcodes

      # Associations:
      has_many :samples, readonly: true
      has_many :studies, readonly: true
      has_many :projects, readonly: true
      has_many :qc_results, readonly: true
      has_many :requests_as_source, readonly: true, class_name: 'Request'
      has_many :requests_as_target, readonly: true, class_name: 'Request'
      has_many :aliquots, readonly: true

      has_many :downstream_assets, readonly: true, polymorphic: true, class_name: 'Receptacle'
      has_many :downstream_wells, readonly: true, class_name: 'Well'
      has_many :downstream_plates, readonly: true, class_name: 'Plate'
      has_many :downstream_tubes, readonly: true, class_name: 'Tube'

      has_many :upstream_assets, readonly: true, polymorphic: true, class_name: 'Receptacle'
      has_many :upstream_wells, readonly: true, class_name: 'Well'
      has_many :upstream_plates, readonly: true, class_name: 'Plate'
      has_many :upstream_tubes, readonly: true, class_name: 'Tube'

      has_many :transfer_requests_as_source, readonly: true, class_name: 'TransferRequest'
      has_many :transfer_requests_as_target, readonly: true, class_name: 'TransferRequest'

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name, readonly: true
      attribute :position, readonly: true
      attribute :state, readonly: true

      # Filters
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }

      # Custom methods

      def position
        {
          'name' => _model.map_description
        }
      end

      # Class method overrides
    end
  end
end
