class Receptacle < Asset
  include Transfer::State
  include Aliquot::Remover
  include Tag::Associations
  include Uuid::Uuidable

  self.inheritance_column = 'sti_type'

  class_attribute :stock_message_template, instance_writer: false

  SAMPLE_PARTIAL = 'assets/samples_partials/asset_samples'.freeze

  belongs_to :map

  # Ideally this would be required, however the current code results in the
  # creation of 'floating' wells, which later get laid out on the plate.
  # We should try and move away from this model.
  belongs_to :labware, required: false

  has_many :transfer_requests_as_source, class_name: 'TransferRequest', foreign_key: :asset_id
  has_many :transfer_requests_as_target, class_name: 'TransferRequest', foreign_key: :target_asset_id
  has_many :upstream_assets, through: :transfer_requests_as_target, source: :asset
  has_many :downstream_assets, through: :transfer_requests_as_source, source: :target_asset

  has_many :requests, inverse_of: :asset, foreign_key: :asset_id
  has_one  :source_request, ->() { includes(:request_metadata) }, class_name: 'Request', foreign_key: :target_asset_id
  has_many :requests_as_source, ->() { includes(:request_metadata) }, class_name: 'Request', foreign_key: :asset_id
  has_many :requests_as_target, ->() { includes(:request_metadata) }, class_name: 'Request', foreign_key: :target_asset_id
  has_many :creation_batches, class_name: 'Batch', through: :requests_as_target, source: :batch
  has_many :source_batches, class_name: 'Batch', through: :requests_as_source, source: :batch

  has_many :asset_group_assets, dependent: :destroy, inverse_of: :asset
  has_many :asset_groups, through: :asset_group_assets

  # A receptacle can hold many aliquots.  For example, a multiplexed library tube will contain more than
  # one aliquot.
  has_many :aliquots, ->() { order(tag_id: :asc, tag2_id: :asc) }, foreign_key: :receptacle_id, autosave: true, dependent: :destroy, inverse_of: :receptacle
  has_many :samples, through: :aliquots
  has_many :studies, ->() { distinct }, through: :aliquots
  has_many :projects, ->() { distinct }, through: :aliquots
  has_one :primary_aliquot, ->() { order(:created_at).readonly }, class_name: 'Aliquot', foreign_key: :receptacle_id

  has_many :state_changes, foreign_key: :target_id

  has_many :tags, through: :aliquots

  has_many :stock_well_links, ->() { stock }, class_name: 'Well::Link', foreign_key: :target_well_id

  has_many :stock_wells, through: :stock_well_links, source: :source_well do
    def attach!(wells)
      attach(wells).tap do |_|
        proxy_association.owner.save!
      end
    end

    def attach(wells)
      proxy_association.owner.stock_well_links.build(wells.map { |well| { type: 'stock', source_well: well } })
    end
  end

  has_many :submissions, ->() { distinct }, through: :transfer_requests_as_target

  # Our receptacle needs to report its tagging status based on the most highly tagged aliquot. This retrieves it
  has_one :most_tagged_aliquot, ->() { order(tag2_id: :desc, tag_id: :desc).readonly }, class_name: 'Aliquot', foreign_key: :receptacle_id

  # DEPRECATED ASSOCIATIONS
  # TODO: Remove these at some point in the future as they're kind of wrong!
  has_one :sample, through: :primary_aliquot
  deprecate sample: 'receptacles may contain multiple samples. This method just returns the first.'
  has_one :get_tag, through: :primary_aliquot, source: :tag
  deprecate get_tag: 'receptacles can contain multiple tags.'

  # def map_description
  delegate :description, to: :map, prefix: true, allow_nil: true

  scope :include_map,         -> { includes(:map) }
  scope :located_at, ->(location) {
    joins(:map).where(maps: { description: location })
  }
  scope :located_at_position, ->(position) { joins(:map).readonly(false).where(maps: { description: position }) }

  # It feels like we should be able to do this with just includes and order, but oddly this causes more disruption downstream
  scope :in_column_major_order,         -> { joins(:map).order('column_order ASC').select('receptacles.*, column_order') }
  scope :in_row_major_order,            -> { joins(:map).order('row_order ASC').select('receptacles.*, row_order') }
  scope :in_inverse_column_major_order, -> { joins(:map).order('column_order DESC').select('receptacles.*, column_order') }
  scope :in_inverse_row_major_order,    -> { joins(:map).order('row_order DESC').select('receptacles.*, row_order') }

  # Named scopes for the future
  scope :include_aliquots, ->() { includes(aliquots: %i(sample tag bait_library)) }
  scope :include_aliquots_for_api, ->() { includes(aliquots: Io::Aliquot::PRELOADS) }
  scope :for_summary, ->() { includes(:map, :samples, :studies, :projects) }
  scope :include_creation_batches, ->() { includes(:creation_batches) }
  scope :include_source_batches, ->() { includes(:source_batches) }
  scope :with_required_aliquots, ->(aliquots_ids) { joins(:aliquots).where(aliquots: { id: aliquots_ids }) }

  scope :for_study_and_request_type, ->(study, request_type) { joins(:aliquots, :requests).where(aliquots: { study_id: study }).where(requests: { request_type_id: request_type }) }

  # This is a lambda as otherwise the scope selects Receptacles
  scope :with_aliquots, -> { joins(:aliquots) }

  # Provide some named scopes that will fit with what we've used in the past
  scope :with_sample_id, ->(id)     { where(aliquots: { sample_id: Array(id)     }).joins(:aliquots) }
  scope :with_sample,    ->(sample) { where(aliquots: { sample_id: Array(sample) }).joins(:aliquots) }

  # Scope for caching the samples of the receptacle
  scope :including_samples, -> { includes(samples: :studies) }

  def display_name
    labware_name = labware.present? ? labware.sanger_human_barcode : '(not on labware)'
    labware_name ||= labware.display_name # In the even the labware is barcodeless (ie strip tubes) use its name
    "#{labware_name}:#{map ? map.description : ''}"
  end

  def sample=(sample)
    aliquots.clear
    aliquots << Aliquot.new(sample: sample)
  end
  deprecate :sample=

  def update_aliquot_quality(suboptimal_quality)
    aliquots.each { |a| a.update_quality(suboptimal_quality) }
    true
  end

  def tag
    get_tag.try(:map_id) || ''
  end
  deprecate :tag

    # We only support wells for the time being
  def latest_stock_metrics(_product, *_args)
    []
  end

  delegate :tag_count_name, to: :most_tagged_aliquot, allow_nil: true
  delegate :asset_type_for_request_types, to: :labware

  extend EventfulRecord
  has_many_events do
    # TODO: Work out which ones we need.
    event_constructor(:create_external_release!,       ExternalReleaseEvent,          :create_for_asset!)
    event_constructor(:create_pass!,                   Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_fail!,                   Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_state_update!,           Event::AssetSetQcStateEvent,   :create_updated!)
    event_constructor(:create_scanned_into_lab!,       Event::ScannedIntoLabEvent,    :create_for_asset!)
    event_constructor(:create_plate!,                  Event::PlateCreationEvent,     :create_for_asset!)
    event_constructor(:create_plate_with_date!,        Event::PlateCreationEvent,     :create_for_asset_with_date!)
    event_constructor(:create_sequenom_stamp!,         Event::PlateCreationEvent,     :create_sequenom_stamp_for_asset!)
    event_constructor(:create_sequenom_plate!,         Event::PlateCreationEvent,     :create_sequenom_plate_for_asset!)
    event_constructor(:create_gel_qc!,                 Event::SampleLogisticsQcEvent, :create_gel_qc_for_asset!)
    event_constructor(:create_pico!,                   Event::SampleLogisticsQcEvent, :create_pico_result_for_asset!)
    event_constructor(:created_using_sample_manifest!, Event::SampleManifestEvent,    :created_sample!)
    event_constructor(:updated_using_sample_manifest!, Event::SampleManifestEvent,    :updated_sample!)
    event_constructor(:updated_fluidigm_plate!, Event::SequenomLoading, :updated_fluidigm_plate!)
    event_constructor(:update_gender_markers!,         Event::SequenomLoading,        :created_update_gender_makers!)
    event_constructor(:update_sequenom_count!,         Event::SequenomLoading,        :created_update_sequenom_count!)
  end
  has_many_lab_events

  has_one_event_with_family 'moved_to_2d_tube'

  delegate :barcode, :sanger_human_barcode, :ean13_barcode, to: :labware

  # Returns the map_id of the first and last tag in an asset
  # eg 1-96.
  # Caution: Used on barcode labels. Avoid using elsewhere as makes assumptions
  #          about tag behaviour which may change shortly.
  # @return [String,nil] Returns nil is no tags, the map_id is a single tag, or the first and
  #                      last map id separated by a hyphen if multiple tags.
  #
  def tag_range
    map_ids = tags.order(:map_id).pluck(:map_id)
    case map_ids.length
    when 0; then nil
    when 1; then map_ids.first
    else "#{map_ids.first}-#{map_ids.last}"
    end
  end

  def attach_tag(tag, tag2 = nil)
    tags = { tag: tag, tag2: tag2 }.compact
    return if tags.empty?
    raise StandardError, 'Cannot tag an empty asset'   if aliquots.empty?
    raise StandardError, 'Cannot tag multiple samples' if aliquots.size > 1
    aliquots.first.update_attributes!(tags)
  end
  alias attach_tags attach_tag

  def name
    "#{labware.display_name} #{map_description}"
  end

  def default_state
    nil
  end

  def primary_aliquot_if_unique
    primary_aliquot if aliquots.count == 1
  end

  def type
    self.class.name.underscore
  end

  def specialized_from_manifest=(*args); end

  def library_information; end

  def library_information=(*args); end

  def assign_tag2(tag)
    aliquots.each do |aliquot|
      aliquot.tag2 = tag
      aliquot.save!
    end
  end

  def created_with_request_options
    aliquots.first&.created_with_request_options || {}
  end

  # Library types are still just a string on aliquot.
  def library_types
    aliquots.pluck(:library_type).uniq
  end

  def set_as_library
    aliquots.each do |aliquot|
      aliquot.set_library
      aliquot.save!
    end
  end

  def outer_request(submission_id)
    transfer_requests_as_target.find_by(submission_id: submission_id).try(:outer_request)
  end

  # Contained samples also works on eg. plate
  alias_attribute :contained_samples, :samples

  self.stock_message_template = 'WellStockResourceIO'

  # Generates a message to broadcast the tube to the stock warehouse
  # tables. Raises an exception if no template is configured for a give
  # asset. In most cases this is because the asset is not a stock
  def register_stock!
    raise StandardError, "No stock template configured for #{self.class.name}. If #{self.class.name} is a stock, set stock_template on the class." if stock_message_template.nil?
    Messenger.create!(target: self, template: stock_message_template, root: 'stock_resource')
  end
end
