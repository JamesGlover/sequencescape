
# Any request involved in building a library should include this module that defines some of the
# most common behaviour, namely the library type and insert size information.
module Request::LibraryManufacture
  def self.included(base)
    base::Metadata.class_eval do
      custom_attribute(:fragment_size_required_from, required: true, integer: true, on: :create)
      custom_attribute(:fragment_size_required_to,   required: true, integer: true, on: :create)
      custom_attribute(:library_type,                required: true, validator: true, selection: true, on: :create)
    end

    base.class_eval do
      extend ClassMethods
      # Generate libraries upfront when the request is generated. Has the following limitations:
      # - Source assets much contain a single sample
      # - The sample must be present in the asset when the request is generated
      # validate :assets_suitable_for_library_creation prevents the restrictions being violated
      # The second condition may be violated if submission templates end up chaining requests
      # upstream of library creation, however no such templates are currently active
      after_create :generate_library
      # Ensures :generate_library behaves predictably
      validate :assets_suitable_for_library_creation, on: :create
    end

    base.const_set(:RequestOptionsValidator, Class.new(DelegateValidation::Validator) do
      delegate_attribute :fragment_size_required_from, :fragment_size_required_to, to: :target, type_cast: :to_i
      validates_numericality_of :fragment_size_required_from, integer_only: true, greater_than: 0
      validates_numericality_of :fragment_size_required_to,   integer_only: true, greater_than: 0
    end)
  end

  module ClassMethods
    def delegate_validator
      self::RequestOptionsValidator
    end
  end

  def insert_size
    Aliquot::InsertSize.new(
      request_metadata.fragment_size_required_from,
      request_metadata.fragment_size_required_to
    )
  end

  def generate_library
    create_library!(
      sample: samples.first,
      parent_library: upstream_libraries.first,
      library_type: LibraryType.find_by!(name: library_type)
    )
  end

  # We shouldn't be violating this constraint, but if we do we want to know, as it could result in
  # data integrity issues.
  # - If we have multiple samples we can probably just switch to has_many libraries without much issue
  # - If there are no samples, then its probably a case of the request being part of a request graph, and the source
  # asset being empty at time of creation. In this case we probably still want to generate the library upfront, but
  # will need to either pass the sample in, or handle library creation elsewhere.
  def assets_suitable_for_library_creation
    return if samples.one? || upstream_libraries.one?
    errors.add(:asset, "contains #{samples.count} samples. Only 1 sample is allowed.")
  end

  delegate :library_type, to: :request_metadata

  # Currently only operates at submission generation
  def upstream_libraries
    (upstream_requests_at_build || []).map(&:library).compact.uniq
  end
end
