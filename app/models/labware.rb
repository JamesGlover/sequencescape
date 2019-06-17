# frozen_string_literal: true

# Labware represents a physical object which moves around the lab.
# It has one or more receptacles.
# This class has been created as part of the {AssetRefactor} when not in
# refactor mode this class is pretty much ignored
class Labware < Asset
  AssetRefactor.when_not_refactored do
    self.table_name = 'assets'
  end

  AssetRefactor.when_refactored do
    include LabwareAssociations
    include Commentable
    include Uuid::Uuidable
    include AssetLink::Associations
    has_many :receptacles, dependent: :restrict_with_exception
    has_many :messengers, as: :target, inverse_of: :target, dependent: :destroy
    has_many :aliquots, through: :receptacles
    has_many :samples, through: :receptacles
    has_many :studies, -> { distinct }, through: :receptacles
    has_many :projects, -> { distinct }, through: :receptacles
    has_many :requests_as_source, through: :receptacles
    has_many :requests_as_target, through: :receptacles
    has_many :transfer_requests_as_source, through: :receptacles
    has_many :transfer_requests_as_target, through: :receptacles
    has_many :submissions, through: :receptacles

    scope :with_required_aliquots, ->(aliquots_ids) { joins(:aliquots).where(aliquots: { id: aliquots_ids }) }
  end

  # This block is enabled when we have the labware table present as part of the AssetRefactor
  # Ie. This is what will happen in future
  AssetRefactor.when_refactored do
    # Named scope for search by query string behaviour
    scope :for_search_query, lambda { |query|
      where('labware.name LIKE :name', name: "%#{query}%")
        .or(with_safe_id(query))
        .includes(:barcodes)
    }
    scope :for_lab_searches_display, -> { includes(:barcodes, requests_as_source: %i[pipeline batch]).order('requests.pipeline_id ASC') }
  end
  # This block is disabled when we have the labware table present as part of the AssetRefactor
  # Ie. This is what will happens now
  AssetRefactor.when_not_refactored do
    # Named scope for search by query string behaviour
    scope :for_search_query, lambda { |query|
      where.not(sti_type: 'Well').where('assets.name LIKE :name', name: "%#{query}%").includes(:barcodes)
           .or(where.not(sti_type: 'Well').with_safe_id(query).includes(:barcodes))
    }
    scope :for_lab_searches_display, -> { includes(:barcodes, requests: %i[pipeline batch]).order('requests.pipeline_id ASC') }
  end
end