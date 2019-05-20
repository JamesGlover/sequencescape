# frozen_string_literal: true

require 'lab_where_client'

#
# A plate is a piece of labware made up of a number of {Well wells}. This class represents the physical piece of plastic.
#
#   - {PlatePuprose}: describes the role a plate has in the lab. In some cases a plate's purpose may change as it gets processed.
#   - {Well}: Plates can have multiple wells (most often 96 or 384) each of which can contain multiple samples.
#   - {PlateType}: Identifies the plates form factor, typically provided by robots to ensure tips are positioned correctly.
#
class Plate < Labware
  include Api::PlateIO::Extensions
  include ModelExtensions::Plate
  include Transfer::Associations
  include Transfer::State::PlateState
  # include PlatePurpose::Associations
  include Barcode::Barcodeable
  include Asset::Ownership::Owned
  include Plate::FluidigmBehaviour
  include SubmissionPool::Association::Plate
  include PlateCreation::CreationChild

  extend QcFile::Associations

  # Shouldn't actually be falling back to this, but its here just in case
  self.default_prefix = 'DN'

  has_qc_files

  belongs_to :plate_purpose, foreign_key: :plate_purpose_id, inverse_of: :plates
  belongs_to :purpose, foreign_key: :plate_purpose_id

  has_many :wells, inverse_of: :plate, foreign_key: :labware_id do
    # Build empty wells for the plate.
    def construct!
      plate = proxy_association.owner
      plate.maps.in_row_major_order.ids.map do |location_id|
        build(map: location)
      end.tap do |wells|
        proxy_association.owner.save!
      end
    end

    # Returns the wells with their pool identifier included
    def with_pool_id
      proxy_association.owner.plate_purpose.pool_wells(self)
    end

    def indexed_by_location
      @index_well_cache ||= index_by(&:map_description)
    end
  end

  # Contained associations all look up through wells (Wells in turn delegate to aliquots)
  has_many :contained_samples, through: :wells, source: :samples
  has_many :conatined_aliquots, through: :wells, source: :aliquots

  # We also look up studies and projects through wells
  has_many :studies, -> { distinct }, through: :wells
  has_many :projects, -> { distinct }, through: :wells
  has_many :well_requests_as_target, through: :wells, source: :requests_as_target
  has_many :well_requests_as_source, through: :wells, source: :requests_as_source
  has_many :in_progress_requests, through: :conatined_aliquots, source: :request
  has_many :orders_as_target, -> { distinct }, through: :well_requests_as_target, source: :order
  # We use stock well associations here as stock_wells is already used to generate some kind of hash.
  has_many :stock_requests, -> { distinct }, through: :stock_well_associations, source: :requests
  has_many :stock_well_associations, -> { distinct }, through: :wells, source: :stock_wells
  has_many :stock_orders, -> { distinct }, through: :stock_requests, source: :order
  has_many :extraction_attributes, foreign_key: 'target_id'
  has_many :siblings, through: :parents, source: :children
  # Transfer requests into a plate are the requests leading into the wells of said plate.
  has_many :transfer_requests, through: :wells, source: :transfer_requests_as_target
  has_many :transfer_requests_as_source, through: :wells
  has_many :transfer_requests_as_target, through: :wells
  has_many :transfer_request_collections, -> { distinct }, through: :transfer_requests_as_source

  # The default state for a plate comes from the plate purpose
  delegate :default_state, to: :plate_purpose, allow_nil: true

  def state
    plate_purpose.state_of(self)
  end

  def update_volume(volume_change)
    ActiveRecord::Base.transaction do
      wells.each do |w|
        w.update_volume(volume_change)
      end
    end
  end

  def occupied_well_count
    wells.with_contents.count
  end

  def summary_hash
    {
      asset_id: id,
      barcode: { ean13_barcode: ean13_barcode, human_readable: human_barcode },
      occupied_wells: wells.with_aliquots.include_map.map(&:map_description)
    }
  end

  def cherrypick_completed
    plate_purpose.cherrypick_completed(self)
  end

  def source_plate
    purpose&.source_plate(self)
  end

  SAMPLE_PARTIAL = 'assets/samples_partials/plate_samples'

  # The type of the barcode is delegated to the plate purpose because that governs the number of wells
  delegate :barcode_type, to: :plate_purpose, allow_nil: true
  delegate :asset_shape, to: :plate_purpose, allow_nil: true
  delegate :supports_multiple_submissions?, to: :plate_purpose
  delegate :dilution_factor, :dilution_factor=, to: :plate_metadata

  scope :include_for_show, -> {
    includes(
      requests: :request_metadata,
      wells: [
        :map_id,
        { aliquots: %i[samples tag tag2] }
      ]
    )
  }
  scope :with_plate_purpose, ->(*purposes) { where(plate_purpose_id: purposes.flatten) }

  # Submissions on requests out of the plate
  # May not have been started yet
  has_many :waiting_submissions, -> { distinct }, through: :well_requests_as_source, source: :submission
  # The requests which were being processed to make the plate
  # This should probably be switched to going through aliquots, but not 100% certain that it wont cause side effects
  # Might just be safer to wait until we've moved off onto the new api
  has_many :in_progress_submissions, -> { distinct }, through: :transfer_requests_as_target, source: :submission

  def submission_ids
    @submission_ids ||= in_progress_submissions.pluck(:submission_id)
  end

  def submission_ids_as_source
    @submission_ids_as_source ||= waiting_submissions.pluck(:submission_id)
  end

  # Prioritised the submissions that have been made from the plate
  # then falls back onto the ones under which the plate was made
  def all_submission_ids
    submission_ids_as_source.presence || submission_ids
  end

  def submissions
    waiting_submissions.presence || in_progress_submissions
  end

  def barcode_dilution_factor_created_at_hash
    return {} if primary_barcode.blank?

    {
      barcode: ean13_barcode.to_s,
      dilution_factor: dilution_factor.to_s,
      created_at: created_at
    }
  end

  def iteration
    iter = siblings # assets sharing the same parent
           .where(plate_purpose_id: plate_purpose_id, sti_type: sti_type) # of the same purpose and type
           .where('labware.created_at <= ?', created_at) # created before or at the same time
           .count('labware.id') # count the siblings.

    iter.zero? ? nil : iter # Maintains compatibility with legacy version
  end

  # Delegate the change of state to our plate purpose.
  def transition_to(state, user, contents = nil, customer_accepts_responsibility = false)
    purpose.transition_to(self, state, user, contents, customer_accepts_responsibility)
  end

  def comments
    @comments ||= CommentsProxy::Plate.new(self)
  end

  def priority
    Submission.joins([
      'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
      'INNER JOIN receptacles ON receptacles.id = reqp.asset_id'
    ])
              .where(receptacles: { labware_id: id }).maximum('submissions.priority') ||
      Submission.joins([
        'INNER JOIN requests as reqp ON reqp.submission_id = submissions.id',
        'INNER JOIN receptacles ON receptacles.id = reqp.target_asset_id'
      ])
                .where(receptacles: { labware_id: id }).maximum('submissions.priority') ||
      0
  end

  # Plates can easily belong to multiple studies, so this method is just misleading.
  def study
    wells.first.try(:study)
  end
  deprecate study: 'Plates can belong to multiple studies, use #studies instead.'

  DEFAULT_SIZE = 96

  self.per_page = 50

  before_create :set_plate_name_and_size

  scope :qc_started_plates, -> {
    select('labware.*')
      .joins('LEFT OUTER JOIN `events` ON events.eventful_id = assets.id LEFT OUTER JOIN `asset_audits` ON asset_audits.asset_id = assets.id')
      .where(["(events.family = 'create_dilution_plate_purpose' OR asset_audits.key = 'slf_receive_plates') AND plate_purpose_id = ?", PlatePurpose.stock_plate_purpose.id])
      .order(id: :desc)
      .includes(:events, :asset_audits)
      .distinct
  }


  scope :with_sample, ->(sample) { includes(:contained_samples).where(samples: { id: sample }) }
  scope :with_requests, ->(requests) {
    join(:requests_as_source).where(requests: { id: requests }).distinct
  }
  scope :output_by_batch, ->(batch) {
    joins(wells: { requests_as_target: :batch })
      .where(batches: { id: batch })
  }

  scope :include_wells, -> { includes(:wells) } do
    def to_include
      [:wells]
    end

    def with(subinclude)
      scoped(include: { wells: subinclude })
    end
  end

  scope :with_wells, ->(wells) {
    join(:wells)
      .where(receptacles: { id: wells } )
      .distinct
  }
  has_many :descendant_plates, class_name: 'Plate', through: :links_as_ancestor, foreign_key: :ancestor_id, source: :descendant
  has_many :descendant_lanes,  class_name: 'Lane', through: :links_as_ancestor, foreign_key: :ancestor_id, source: :descendant
  has_many :tag_layouts, dependent: :destroy

  scope :with_descendants_owned_by, ->(user) {
    joins(descendant_plates: :plate_owner)
      .where(plate_owners: { user_id: user })
      .distinct
  }

  scope :source_plates, -> {
    joins(:plate_purpose)
      .where('plate_purposes.id = plate_purposes.source_purpose_id')
  }

  scope :with_wells_and_requests, -> {
    eager_load(wells: [
      :uuid_object, :map,
      {
        requests_as_target: [
          { initial_study: :uuid_object },
          { initial_project: :uuid_object },
          { asset: { aliquots: :sample } }
        ]
      }
    ])
  }

  def self.search_for_plates(params)
    with_faculty_sponsor_ids(params[:faculty_sponsor_ids] || nil)
      .with_study_id(params[:study_id] || nil)
      .with_plate_purpose_ids(params[:plate_purpose_ids] || nil)
      .created_on_or_after(params[:start_date] || nil)
      .created_on_or_before(params[:end_date] || nil)
      .filter_by_barcode(params[:barcodes] || nil) #  .where.not(barcode: nil)
      .distinct
  end

  scope :with_faculty_sponsor_ids, ->(faculty_sponsor_ids) {
    if faculty_sponsor_ids.present?
      joins(studies: { study_metadata: :faculty_sponsor })
        .where(faculty_sponsors: { id: faculty_sponsor_ids })
    end
  }

  scope :with_study_id, ->(study_id) { joins(:studies).where(studies: { id: study_id }) if study_id.present? }

  scope :with_plate_purpose_ids, ->(plate_purpose_ids) {
    joins(:plate_purpose).where(plate_purposes: { id: plate_purpose_ids }) if plate_purpose_ids.present?
  }

  scope :created_on_or_after, ->(date) { where('assets.created_at >= ?', date.midnight) if date.present? }
  scope :created_on_or_before, ->(date) { where('assets.created_at <= ?', date.end_of_day) if date.present? }

  def maps
    Map.where_plate_size(size).where_plate_shape(asset_shape)
  end

  def find_map_by_rowcol(row, col)
    # Count from 0
    maps.find_by(description: map_description(row, col))
  end

  def map_description(row, col)
    asset_shape.location_from_row_and_column(row, col + 1, size)
  end

  def find_well_by_rowcol(row, col)
    map_description = map_description(row, col)
    return nil if map_description.nil?

    find_well_by_name(map_description)
  end

  def add_well_holder(well)
    wells << well
  end

  def add_well(well, row = nil, col = nil)
    add_well_holder(well)
    well.map = find_map_by_rowcol(row, col) if row
  end

  def add_well_by_map_description(well, map_description)
    add_well_holder(well)
    well.map = Map.find_by(description: map_description, asset_size: size)
    well.save!
  end

  def add_and_save_well(well, row = nil, col = nil)
    add_well(well, row, col)
    well.save!
  end

  def find_well_by_name(well_name)
    if wells.loaded?
      wells.indexed_by_location[well_name]
    else
      wells.located_at_position(well_name).first
    end
  end
  alias find_well_by_map_description find_well_by_name

  def plate_rows
    ('A'..('A'.getbyte(0) + height - 1).chr.to_s).to_a
  end

  def plate_columns
    (1..width)
  end

  def set_plate_type(result)
    add_descriptor(Descriptor.new(name: 'Plate Type', value: result))
    save
  end

  def plate_type
    plate_type_descriptor.presence || PlateType.first.name
  end

  def details
    purpose.try(:name) || 'Unknown plate purpose'
  end

  def stock_role
    well_requests_as_source.first&.role
  end

  # A plate has a sample with the specified name if any of its wells have that sample.
  def sample?(sample_name)
    wells.any? do |well|
      well.aliquots.any? { |aliquot| aliquot.sample.name == sample_name }
    end
  end

  def storage_location
    @storage_location ||= obtain_storage_location
  end

  attr_reader :storage_location_service

  def self.plate_ids_from_requests(requests)
    with_requests(requests).pluck(:id)
  end

  # Should return true if any samples on the plate contains gender information
  def contains_gendered_samples?
    contained_samples.with_gender.any?
  end

  def create_sample_tubes
    wells.map(&:create_child_sample_tube)
  end

  def create_sample_tubes_and_print_barcodes(barcode_printer)
    sample_tubes = create_sample_tubes
    print_job = LabelPrinter::PrintJob.new(barcode_printer.name,
                                           LabelPrinter::Label::PlateToTubes,
                                           sample_tubes: sample_tubes)
    print_job.execute

    sample_tubes
  end

  def self.create_sample_tubes_asset_group_and_print_barcodes(plates, barcode_printer, study)
    return nil if plates.empty?

    plate_barcodes = plates.map(&:barcode_number)
    asset_group = AssetGroup.find_or_create_asset_group("#{plate_barcodes.join('-')} #{Time.current.to_formatted_s(:sortable)} ", study)
    plates.each do |plate|
      next if plate.wells.empty?

      asset_group.assets << plate.create_sample_tubes_and_print_barcodes(barcode_printer)
    end

    return nil if asset_group.assets.empty?

    asset_group.save!

    asset_group
  end

  def stock_plate?
    return true if plate_purpose.nil?

    plate_purpose.stock_plate? && plate_purpose.attatched?(self)
  end

  def stock_plate
    @stock_plate ||= stock_plate? ? self : lookup_stock_plate
  end

  def ancestor_of_purpose(ancestor_purpose_id)
    return self if plate_purpose_id == ancestor_purpose_id

    ancestors.order(created_at: :desc).find_by(plate_purpose_id: ancestor_purpose_id)
  end

  def ancestors_of_purpose(ancestor_purpose_id)
    return [self] if plate_purpose_id == ancestor_purpose_id

    ancestors.order(created_at: :desc).where(plate_purpose_id: ancestor_purpose_id)
  end

  def find_study_abbreviation_from_parent
    parent.try(:wells).try(:first).try(:study).try(:abbreviation)
  end

  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    attributes[:sanger_barcode] = safe_sanger_barcode(attributes[:sanger_barcode] || {})
    create!(attributes, &block)
  end

  def self.safe_sanger_barcode(sanger_barcode)
    if sanger_barcode[:number].blank? || Barcode.sanger_barcode(sanger_barcode[:prefix], sanger_barcode[:number]).exists?
      { number: PlateBarcode.create.barcode, prefix: sanger_barcode[:prefix] }
    else
      sanger_barcode
    end
  end

  def number_of_blank_samples
    wells.with_blank_samples.count
  end

  def default_plate_size
    DEFAULT_SIZE
  end

  def scored?
    wells.any?(&:get_gel_pass)
  end

  def buffer_required?
    wells.any?(&:buffer_required?)
  end

  def valid_positions?(positions)
    unique_positions_from_caller = positions.sort.uniq
    unique_positions_on_plate = maps.where_description(unique_positions_from_caller)
                                    .distinct
                                    .pluck(:description).sort
    unique_positions_on_plate == unique_positions_from_caller
  end

  def name_for_label
    name
  end

  extend Metadata
  has_metadata do
  end

  def height
    asset_shape.plate_height(size)
  end

  def width
    asset_shape.plate_width(size)
  end

  # This method returns a map from the wells on the plate to their stock well.
  def stock_wells
    # Optimisation: if the plate is a stock plate then it's wells are it's stock wells!]
    if stock_plate?
      wells.with_pool_id.each_with_object({}) { |w, store| store[w] = [w] }
    else
      wells.include_stock_wells.with_pool_id.each_with_object({}) do |w, store|
        storted_stock_wells = w.stock_wells.sort_by { |sw| sw.map.column_order }
        store[w] = storted_stock_wells unless storted_stock_wells.empty?
      end.tap do |stock_wells_hash|
        raise "No stock plate associated with #{id}" if stock_wells_hash.empty?
      end
    end
  end

  def convert_to(new_purpose)
    update!(plate_purpose: new_purpose)
  end

  def compatible_purposes
    PlatePurpose.compatible_with_purpose(purpose)
  end

  def well_hash
    @well_hash ||= wells.include_map.includes(:well_attribute).index_by(&:map_description)
  end

  def update_qc_values_with_parser(parser)
    ActiveRecord::Base.transaction do
      qc_assay = QcAssay.new
      parser.each_well_and_parameters do |position, well_updates|
        # We might have a nil well if a plate was only partially cherrypicked
        well = well_hash[position] || next
        well_updates.each do |attribute, value|
          QcResult.create!(asset: well, key: attribute, unit_value: value, assay_type: parser.assay_type, assay_version: parser.assay_version, qc_assay: qc_assay)
        end
      end
    end
    true
  end

  def samples_in_order(order_id)
    Sample.for_plate_and_order(id, order_id)
  end

  def samples_in_order_by_target(order_id)
    Sample.for_plate_and_order_as_target(id, order_id)
  end

  def team
    ProductLine.joins([
      'INNER JOIN request_types ON request_types.product_line_id = product_lines.id',
      'INNER JOIN requests ON requests.request_type_id = request_types.id',
      'INNER JOIN well_links ON well_links.source_well_id = requests.asset_id AND well_links.type = "stock"',
      'INNER JOIN receptacles ON receptacles.id = well_links.target_well_id'
    ]).find_by(receptacles: { labware_id: id }).try(:name) || 'UNKNOWN'
  end

  alias friendly_name human_barcode
  def subject_type
    'plate'
  end

  def labwhere_location
    @labwhere_location ||= lookup_labwhere_location
  end

  # Plates use a different counter to tubes, and prior to the foreign barcodes update
  # this method would have fallen back to Barcodable#generate tubes, and potentially generated
  # an invalid plate barcode. In the future we probably want to scrap this approach entirely,
  # and generate all barcodes in the plate style. (That is, as part of the factory on, eg. plate purpose)
  def generate_barcode
    raise StandardError, "#generate_barcode has been called on plate, which wasn't supposed to happen, and probably indicates a bug."
  end

  def sanger_barcode=(attributes)
    barcodes << Barcode.build_sanger_code39(attributes)
  end

  def after_comment_addition(comment)
    comments.add_comment_to_submissions(comment)
  end

  private

  def plate_type_descriptor
    descriptor_value('Plate Type')
  end

  def obtain_storage_location
    if labwhere_location.present?
      @storage_location_service = 'LabWhere'
      labwhere_location
    else
      @storage_location_service = 'None'
      'LabWhere location not set. Could this be in ETS?'
    end
  end

  def lookup_labwhere_location
    lookup_labwhere(machine_barcode) || lookup_labwhere(human_barcode)
  end

  def lookup_labwhere(barcode)
    begin
      info_from_labwhere = LabWhereClient::Labware.find_by_barcode(barcode)
    rescue LabWhereClient::LabwhereException => e
      return "Not found (#{e.message})"
    end
    return info_from_labwhere.location.location_info if info_from_labwhere.present? && info_from_labwhere.location.present?
  end

  def lookup_stock_plate
    spp = PlatePurpose.considered_stock_plate.pluck(:id)
    ancestors.order('created_at DESC').find_by(plate_purpose_id: spp)
  end

  def set_plate_name_and_size
    self.name = "Plate #{human_barcode}" if name.blank?
    self.size = default_plate_size if size.nil?
  end
end
