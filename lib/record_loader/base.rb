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

    class_attribute :config_folder

    #
    # Create a new config loader from yaml files
    #
    # @param files [Array,NilClass] pass in an array of files to load, or nil to load all files.
    # @param directory [Pathname, String] The directory from which to load the files.
    #   defaults to config/default_records/plate_purposes
    #
    def initialize(files: nil, directory: default_path)
      @path = directory.is_a?(Pathname) ? directory : Pathname.new(directory)
      @files = @path.glob("*#{EXTENSION}").select { |child| load_file?(files, child) }
      load_config
    end

    private

    #
    # The default path to load config files from
    #
    # @return [Pathname] The directory containing trhe yml files
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
      list.nil? || list.include?(file.basename(EXTENSION).to_s)
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
