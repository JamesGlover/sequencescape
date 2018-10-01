# frozen_string_literal: true

module SampleManifestExcel
  module Tags
    ##
    # Used for testing purposes.
    # Creates a multidimensional array of tag and tag2 oligos
    # which can be inserted into a download spreadsheet based on row numbers.
    class ExampleData
      BASES = %w[A C G T].freeze

      attr_reader :tag_oligos, :tag2_oligos

      def initialize
        create_products
      end

      ##
      # Take a certain section of the data based on the number of rows
      # needed for a particular download.
      # If duplicate is set to true the tags will be invalid for a
      # multiplexed library tube.
      def take(first, last, duplicate = false)
        {}.tap do |hsh|
          (first..last).each_with_index do |n, i|
            hsh[n] = { tag_oligo: tag_oligos[i].join, tag2_oligo: tag2_oligos[i].join }
          end
          hsh[last] = hsh[first] if duplicate
        end
      end

      ##
      # Version of take method for creating Tag group and Index column values for older style
      # multiplex tube manifest uploads.
      # If duplicate is set to true the tag groups and indexes will be invalid for a
      # multiplexed library tube.
      def take_as_groups_and_indexes(first, last, duplicate = false)
        tag_groups = FactoryBot.create_list(:tag_group, 2, tag_count: (last - first) + 1)

        {}.tap do |hsh|
          (first..last).each_with_index do |n, i|
            hsh[n] = { tag_group: tag_groups[0].name, tag_index: tag_groups[0].tags[i].map_id.to_s, tag2_group: tag_groups[1].name, tag2_index: tag_groups[1].tags[i].map_id.to_s }
          end
          hsh[last] = hsh[first] if duplicate
        end
      end

      private

      def create_products
        @tag_oligos = BASES.product(BASES)
        @tag2_oligos = tag_oligos.reverse
      end
    end
  end
end