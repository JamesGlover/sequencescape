# frozen_string_literal: true

# Provides tools for seeding / updating database records
module RecordLoader
  # Inherit from RecordLoader base to automatically load one or more yaml files
  # into a @config hash. Config folders are found in config/default_records
  # and each loader should specify its own subfolder by setting the config_folder
  # class attribute.
  class Base
    BASE_CONFIG_PATH = %w[config default_records].freeze
    EXTENSION = '.yml'
    DEV_IDENTIFIER = '.dev'
    WIP_IDENTIFIER = '.wip'

    class_attribute :config_folder

    # A RecordFile is a wrapper to handle categorization of the yaml files
    class RecordFile
      # Cretae a RecordFile wrapper for a given file
      # @param filepath [Pathname] The path of the file to wrap
      def initialize(record_file)
        @record_file = record_file
      end

      # Returns the name of the file, minus the extension and dev/wip flags
      # @return [String] The name of the file eg. "000_purpose"
      def basename
        without_extension.delete_suffix(WIP_IDENTIFIER)
                         .delete_suffix(DEV_IDENTIFIER)
      end

      def dev?
        without_extension.ends_with?(DEV_IDENTIFIER)
      end

      def wip?
        without_extension.ends_with?(WIP_IDENTIFIER)
      end

      private

      def without_extension
        @record_file.basename(EXTENSION).to_s
      end
    end

    #
    # Create a new config loader from yaml files
    #
    # @param files [Array<String>,NilClass] pass in an array of file names to load, or nil to load all files.
    #                                       Dev and wip flags will be ignored for files passed in explicitly
    # @param directory [Pathname, String] The directory from which to load the files.
    #   defaults to config/default_records/plate_purposes
    # @param dev [Boolean] Override the rails environment to generate (or not) data from dev.yml files.
    #
    def initialize(files: nil, directory: default_path, dev: Rails.env.development?)
      @path = directory.is_a?(Pathname) ? directory : Pathname.new(directory)
      @dev = dev
      @files = @path.glob("*#{EXTENSION}").select { |child| load_file?(files, RecordFile.new(child)) }
      load_config
    end

    #
    # Opens a transaction and creates or updates each of the records in the yml files
    # via the #create_or_update! method
    #
    # @return [Void]
    def create!
      ActiveRecord::Base.transaction do
        @config.each do |key, config|
          create_or_update!(key, config)
        end
      end
    end

    private

    def wip_list
      ENV.fetch('WIP', '').split(',')
    end

    #
    # The default path to load config files from
    #
    # @return [Pathname] The directory containing the yml files
    #
    def default_path
      Rails.root.join(*BASE_CONFIG_PATH, config_folder)
    end

    #
    # Indicates that a file should be loaded
    #
    # @param [Array] list provides an array of files (minus extenstions) to load
    # @param [Pathname] file The file to check
    #
    # @return [Boolean] returns true if the file should be loaded
    #
    def load_file?(list, file)
      if list.nil?
        return @dev if file.dev?
        return wip_list.include?(file.basename) if file.wip?

        true
      else
        # If we've provided a list, that's all that matters
        list.include?(file.basename)
      end
    end

    #
    # Load the appropriate configuration files into @config
    #
    def load_config
      @config = @files.each_with_object({}) do |file, store|
        latest_file = YAML.load_file(file)
        duplicate_keys = store.keys & latest_file.keys
        Rails.logger.warn "Duplicate keys in #{@path}: #{duplicate_keys}" unless duplicate_keys.empty?
        store.merge!(latest_file)
      end
    end
  end
end
