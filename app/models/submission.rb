class Submission < ActiveRecord::Base
  include Uuid::Uuidable
  extend  Submission::StateMachine
  include Submission::DelayedJobBehaviour
  include Submission::AssetGroupBehaviour
  include Submission::QuotaBehaviour
  include Submission::RequestOptionsBehaviour
  include Submission::AccessionBehaviour
  include ModelExtensions::Submission

  include Workflowed
  include DelayedJobEx

  self.inheritance_column = "sti_type"

  # Required at initial construction time ...
  belongs_to :study
  validates_presence_of :study

  belongs_to :project
  validates_presence_of :project

  belongs_to :user
  validates_presence_of :user
  
  belongs_to :workflow, :class_name => 'Submission::Workflow'
  validates_presence_of :workflow

  serialize :request_types
  validates_presence_of :request_types

  # Created during the lifetime ...
  has_many :requests
  has_many :items, :through => :requests

  serialize :item_options

  named_scope :for_studies, lambda {|*args| {:conditions => { :study_id => args[0]} } }
  
  cattr_reader :per_page
  @@per_page = 500
  named_scope :including_associations_for_json, { :include => [:uuid_object, {:assets => [:uuid_object] }, { :project => :uuid_object }, { :study => :uuid_object }, :user] }

  # Before destroying this instance we should cancel all of the requests it has made
  before_destroy :cancel_all_requests_on_destruction

  def cancel_all_requests_on_destruction
    requests.all.each do |request|
      request.cancel!  # Cancel first to prevent event doing something stupid
      request.events.create!(:message => "Submission #{self.id} as destroyed")
    end
  end
  private :cancel_all_requests_on_destruction
  
  def self.render_class
    Api::SubmissionIO
  end
  
  def url_name
    "submission"
  end
  alias_method(:json_root, :url_name)
  
  def asset_uuids
    assets.select{ |asset| ! asset.nil? }.map(&:uuid) if assets
  end

  # TODO[xxx]: I don't like the name but this should disappear once the UI has been fixed
  def self.prepare!(options)
    constructor = options.delete(:template) || self
    constructor.create!(options.merge(:assets => options.fetch(:assets, [])))
  end

  def self.build!(options)
    ActiveRecord::Base.transaction do
      submission = self.prepare!(options)
      submission.built!
      submission
    end
  end
  # TODO[xxx]: ... to here really!

  def safe_to_delete?
    ActiveSupport::Deprecation.warn "Submission#safe_to_delete? may not recognise all states"
    unless self.ready?
      requests_in_progress = self.requests.select{|r| r.state != 'pending' || r.state != 'waiting'}
      requests_in_progress.empty? ? true : false
    else
      return true
    end
  end

  def process_submission!
    build_request_graph!
  end
  alias_method(:create_requests, :process_submission!)

  def multiplexed?
    RequestType.find(self.request_types).any?(&:for_multiplexing?)
  end

  def is_asset_applicable_to_type?(request_type, asset)
    request_type.asset_type == asset.asset_type_for_request_types.name
  end
  private :is_asset_applicable_to_type?

  def multiplex_started_passed
    multiplex_started_passed_result = false
    if self.multiplexed?
      requests = Request.find_all_by_submission_id(self.id)
      states = requests.map(&:state).uniq
      if ( states.include?("started") || states.include?("passed") )
        multiplex_started_passed_result = true
      end
    end
    return multiplex_started_passed_result
  end

  def create_request_of_type!(request_type, attributes = {}, &block)
    request_type.create!(attributes) do |request|
      request.workflow                    = workflow
      request.project                     = project
      request.study                       = study
      request.user                        = user
      request.submission_id               = id
      request.request_metadata_attributes = request_type.extract_metadata_from_hash(request_options)
      request.state                       = initial_request_state(request_type)

      if request.asset.present?
        # TODO: This should really be an exception but not sure of the side-effects at the moment
        request.asset  = nil unless is_asset_applicable_to_type?(request_type, request.asset)
      end
    end
  end

  def move_to_submission(assets, current_user, submission)
    raise Exception.new, "Type error" unless submission.instance_of? Submission
    assets.each do |asset|
      self.move_assets(asset, submission, current_user)
      self.save
    end
    unless self.assets.nil?
      self.assets = self.assets - assets
      self.save
    end
  end

  def move_to_new_submission(assets, current_user, study_to)
    raise Exception.new, "Type error" unless study_to.instance_of? Study
    new_submission = self.duplicate
    new_submission.assets = assets
    new_submission.study = study_to
    self.move_to_submission(assets, current_user, new_submission)
    new_submission.save
  end

  def duplicate(&block)
    create_parameters = template_parameters
    new_submission = Submission.create(create_parameters.merge( :study => self.study,:workflow => self.workflow,
          :user => self.user, :assets => self.assets, :state => self.state,
          :request_types => self.request_types,
          :request_options => self.request_options,
          :comments => self.comments,
          :project_id => self.project_id), &block)
    new_submission.save
    return new_submission
  end

  def move_assets(asset, target, current_user)
    sample = asset.sample
    self.requests.each do |request|
      if request.sample_id == sample.id
        request.study_id = target.study_id
        request.submission_id =  target.id
        # TODO: Remove duplicate associations
        item = request.item
        item.study_id = target.study_id
        item.submission_id = target.id
        item.save
        request.save
      end

    end

    target.study.events.create(
    :message => "Submission #{target.id} is created by Move Sample #{sample.id}",
    :created_by => current_user.login,
    :content => "",
    :of_interest_to => "administrators"
    )

  end
  deprecate :move_assets

  #  attributes which are not saved for a submission but can be pre-set via SubmissionTemplate
  # return a list of request_types lists  (a sequence of choices) to display in the new view
  attr_accessor_with_default :request_type_ids_list, [[]]
  attr_accessor :info_differential # aggrement text to display when creating a new submission
  attr_accessor :customize_partial # the name of a partial to render. 
  DefaultAssetInputMethods = ["select an asset group"]
  #DefaultAssetInputMethods = ["select an asset group", "enter a list of asset ids", "enter a list of asset names", "enter a list of sample names"]
  attr_accessor_with_default :asset_input_methods, DefaultAssetInputMethods

  # return a hash with the values needed to be saved as a template
  # beware nil values are filtered to not overwride default value set in the initializer
  # (in case these default value are added after a template has been save)
  # So don't forget to filter again if you override this method.
  def template_parameters
    {
      :request_options => request_options,
      :request_types => request_types,
      :comments => comments,
      :request_type_ids_list => request_type_ids_list,
      :workflow_id => workflow.id,
      :info_differential => info_differential,
      :customize_partial => customize_partial,
      :input_field_infos => @input_field_infos,
      :asset_input_methods => asset_input_methods != DefaultAssetInputMethods ? asset_input_methods : nil
    }.reject { |k,v| v.nil?}
  end

  def request_types_list
    request_type_ids_list.map { |ids| RequestType.find(ids) }
  end

  def filter_asset_groups(asset_groups)
    return asset_groups
  end

  def request_attributes
    attributes = ActiveSupport::OrderedHash.new
    request_types_list.flatten.each do |request_type|
      request_type.request_class::Metadata.attribute_details.each do |att|
        old_attribute = attributes[att.name]
        attributes[att.name] = att unless old_attribute and old_attribute.required? # required attributes have a priority
      end
      request_type.request_class::Metadata.association_details.each do |att|
        attributes[att.name] = att
      end
    end

    attributes.values
  end

  # Return the list of input fields to edit when creating a new submission
  # meant to be overidden
  # the default use request property
  def input_field_infos()
    return @input_field_infos if @input_field_infos
    return compute_input_field_infos
  end

  # we don't call it input_field_infos= because it has a slightly different meanings
  # if input_field_infos is computed it override the computation
  # this is meant do be used only when creating submission template
  def set_input_field_infos(infos)
    @input_field_infos = infos
  end


  def initial_request_state(request_type)
    (request_options || {}).fetch(:initial_state, {}).fetch(request_type.id, request_type.initial_state).to_s
  end
  private :initial_request_state

  def next_request_type_id(request_type_id)
    request_type_ids = request_types.map(&:to_i)
    request_type_ids[request_type_ids.index(request_type_id)+1]
  end

  def next_requests(request)
    return request.target_asset.requests if request.target_asset

    next_request_type_id = self.next_request_type_id(request.request_type_id)
    sibling_requests = requests.select { |r| r.request_type_id == request.request_type_id}
    next_possible_requests = requests.select { |r| r.request_type_id == next_request_type_id}

    #we need to find the position of the request within its sibling and use the same index
    #in the next_possible ones.

    [sibling_requests, next_possible_requests].map do |request_list|
      request_list.sort! { |a, b| a.id <=> b.id }
    end

    # The divergence_ratio should be equal to the multiplier if there is one and so the same for every requests
    # should work also for convergent a request (ration < 1.0))

    divergence_ratio = 1.0* next_possible_requests.size / sibling_requests.size
    index = sibling_requests.index(request)

    next_possible_requests[index*divergence_ratio,[ 1, divergence_ratio ].max]
  end

  def compute_input_field_infos()
    details = OpenStruct.new(self.request_options)
    request_attributes.uniq.map { |attribute| attribute.to_field_info(details) }
  end
  protected :compute_input_field_infos
end

class Array
  def intersperse(separator)
    (inject([]) { |a,v|  a+[v,separator] })[0...-1]
  end
end

