# frozen_string_literal: true

module SampleManifestExcel
  module SpecialisedField
    ##
    # The library type is a value which must already exist.
    # Weirdly the library type is stored as a value rather than an association.
    class LibraryType
      include Base
      include ValueRequired

      validate :check_library_type_exists

      def update(attributes = {})
        return unless valid? && attributes[:aliquot].present?
        attributes[:aliquot].library_type_from_manifest = library_type
      end

      private

      def library_type
        @library_type ||= ::LibraryType.find_by(name: value)
      end

      def check_library_type_exists
        return if library_type.present?
        errors.add(:base, "could not find #{value} library type.")
      end
    end
  end
end
