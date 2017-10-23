module WorkOrders
  #
  # Class WorkOrders::Options tracks default values for work order
  # options, and sets up validations for variable ones.
  #
  # @author Genome Research Ltd.
  #
  class Options
    include ConfigurationLoader::Equality
    #
    # Class Validator provides actual validation of records
    #
    # A note on adding new validation types:
    # 1) Add a method named after your validation type
    # 2) This should accept four arguments
    #    - The name of the attribute being validated
    #    - Any configuration parameters
    #    - The record to be validated
    # @author Genome Research Ltd.
    #
    class Validator
      include ConfigurationLoader::Equality

      def initialize
        @validations = []
      end
      #
      # Validates the record, and adds appropriate error messages
      #
      # @param [WorkOrder] record The Work order to be validated
      #
      # @return [Bool] true if all validations pass.
      #
      def validate(record)
        @validations.reduce(true) do |valid, validator|
          send(*validator, record) && valid
        end
      end

      #
      # Add a new option validator
      #
      # @param [Symbol] validator The method used to validate
      # @param [String] attribute The attribute that will be validated
      # @param [Hash] parameters Optional additional parameters passed in to the validation method
      #
      def add_validator(validator, attribute, parameters = nil)
        @validations << [ validator, attribute, parameters ].freeze
      end

      private
      #
      # Validates static attributes. Ensures that the value hasn't been modified
      # from the default.
      #
      # @param [Sting] attribute The name of the attribute to validate
      # @param [Object] expected_value The expected value of the attribute
      # @param [WorkOrder] record The WorkOrder being validated
      #
      # @return [<type>] <description>
      #
      def static(attribute, expected_value, record)
        return true if record.options[attribute] == expected_value
        record.errors.add(attribute, "should be #{expected_value}")
        false
      end

      def selection(attribute, parameters, record)
        return true if parameters['options'].include? record.options[attribute]
        record.errors.add(attribute, 'is not an accepted value')
        false
      end
    end

    attr_reader :defaults, :dynamic, :validator

    def initialize(config)
      @defaults = {}
      @validator = WorkOrders::Options::Validator.new
      self.static = config.fetch('static', {})
      self.dynamic = config.fetch('dynamic', {})
    end

    def static=(static_attributes)
      @defaults.merge!(static_attributes)
      static_attributes.each do |attribute, value|
        validator.add_validator :static, attribute, value
      end
    end

    def dynamic=(dynamic_attributes)
      dynamic_attributes.each do |attribute, options|
        @defaults[attribute] = options['default'] if options['default']
        validator.add_validator(options['type'].to_sym, attribute, options['parameters']) if options['type']
      end
      @dynamic = dynamic_attributes.freeze
    end
  end
end
