
class Request::LibraryCreation < CustomerRequest
  include Request::CustomerResponsibility

  # In the unlikely event we destroy a request, we destroy a library.
  # If the library has been used, this process will fail, thanks to the
  # foreign key on aliquots. This assumes one sample per library_request.
  has_one :library, dependent: :destroy, foreign_key: :request_id, inverse_of: :request

  # Generate libraries upfront when the request is generated. Has the following limitations:
  # - Source assets much contain a single sample
  # - The sample must be present in the asset when the request is generated
  # validate :assets_suitable_for_library_creation prevents the restrictions being violated
  # The second condition may be violated if submission templates end up chaining requests
  # upstream of library creation, however no such templates are currently active
  after_create :generate_library
  # Ensures :generate_library behaves predictably
  validate :assets_suitable_for_library_creation

  # Override the behaviour of Request so that we do not copy the aliquots from our source asset
  # to the target when we are passed.  This is actually done by the TransferRequest from plate
  # to plate as it goes through being processed.
  def on_started
    # Override the default behaviour to not do the transfer
  end

  # Add common pool information, like insert size and library type
  def update_pool_information(pool_information)
    pool_information.merge!(
      insert_size: { from: insert_size.from, to: insert_size.to },
      library_type: { name: library_type }
    )
  end

  # Convenience helper for ensuring that the fragment size information is properly treated.
  # The columns in the database are strings and we need them to be integers, hence we force
  # that here.
  def self.fragment_size_details(minimum = :no_default, maximum = :no_default)
    minimum_details, maximum_details = { required: true, integer: true }, { required: true, integer: true }
    minimum_details[:default] = minimum unless minimum == :no_default
    maximum_details[:default] = maximum unless maximum == :no_default

    class_eval do
      has_metadata as: Request do
        # Redefine the fragment size attributes as they are fixed
        custom_attribute(:fragment_size_required_from, minimum_details)
        custom_attribute(:fragment_size_required_to, maximum_details)
        custom_attribute(:gigabases_expected, positive_float: true)
      end
    end
    const_get(:Metadata).class_eval do
      def fragment_size_required_from
        super.try(:to_i)
      end

      def fragment_size_required_to
        super.try(:to_i)
      end
    end
  end

  has_metadata as: Request do
  end

  # Unfortunately this needs to remain beneath has_metadata, otherwise it modifies
  # the base Request::Metadata class. This is probably a situation we should fix
  include Request::LibraryManufacture
  #
  # Passed into cloned aliquots at the beginning of a pipeline to set
  # appropriate options
  #
  #
  # @return [Hash] A hash of aliquot attributes
  #
  def aliquot_attributes
    {
      study_id: initial_study_id,
      project_id: initial_project_id,
      library_type: library_type,
      insert_size: insert_size,
      request_id: id
    }
  end

  def library_creation?
    true
  end

  private

  # We shouldn't be violating this constraint, but if we do we want to know, as it could result in
  # data integrity issues.
  # - If we have multiple samples we can probably just switch to has_many libraries without much issue
  # - If there are no samples, then its probably a case of the request being part of a request graph, and the source
  # asset being empty at time of creation. In this case we probably still want to generate the library upfront, but
  # will need to either pass the sample in, or handle library creation elsewhere.
  def assets_suitable_for_library_creation
    errors.add(:asset, "contains #{samples.count} samples. Only 1 sample is allowed.") unless samples.one?
  end

  def generate_library
    create_library!(
      name: "#{asset.external_identifier}##{id}",
      sample: samples.first,
      library_type: LibraryType.find_by!(name: library_type)
    )
  end
end
