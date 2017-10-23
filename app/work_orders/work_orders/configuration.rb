module WorkOrders
  #
  # Class WorkOrders::Configuration provides a means of loading the work order configuration files
  # can probably be DRYed out alongside SampleManifestExcel and Accessioning but at the moment I'm jus
  # copying the pattern.
  #
  class Configuration
    include ConfigurationLoader::Helpers
    include ConfigurationLoader::Equality

    FILES = [:work_order_types].freeze

    attr_accessor :folder
    attr_reader :loaded, :files, :work_order_types

    def initialize
      @files = FILES.dup
      yield self if block_given?
    end

    def add_file(file)
      @files << file.to_sym
      class_eval { attr_accessor file.to_sym }
    end

    def load!
      return unless folder.present?
      FILES.each do |file|
        send("#{file}=", load_file(folder, file.to_s))
      end
      @loaded = true
    end

    def work_order_types=(config)
      @work_order_types = WorkOrderTypesList.new(config).freeze
    end

    def test_work_order_types
      raise StandardError, "Can only use test work order types in test environment" unless Rails.env.test?
      @work_order_types ||= WorkOrderTypesList.new({})
    end

    def loaded?
      loaded
    end
  end
end
