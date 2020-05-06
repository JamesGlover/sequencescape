# frozen_string_literal: true

module RecordLoader
  # Creates the specified plate types if they are not present
  class PlateTypeLoader < RecordLoader::Base
    self.config_folder = 'plate_types'

    def create_or_update!(name, options)
      PlateType.create_with(options).find_or_create_by!(name: name)
    end
  end
end
