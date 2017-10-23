#
# Module ConfigurationLoader provides tools to assist libraries
# and other sub components in the loading of configurations
#
module ConfigurationLoader
  module Helpers
    def load_file(folder, filename)
      YAML.load_file(Rails.root.join(folder, "#{filename}.yml")).with_indifferent_access
    end
  end
  module Equality
    include Comparable

    def to_a
      instance_variables.map { |v| instance_variable_get(v) }.compact
    end

    ##
    # Two objects are comparable if all of their instance variables that are present
    # are comparable.
    def <=>(other)
      return unless other.is_a?(self.class)
      to_a <=> other.to_a
    end
  end
end
