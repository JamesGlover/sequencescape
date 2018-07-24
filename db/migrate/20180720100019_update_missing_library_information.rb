# frozen_string_literal: true

# Longer running migration to update libraries with the original asset's
# external identifier.
class UpdateMissingLibraryInformation < ActiveRecord::Migration[5.1]
  # Define a new class for this migration with a link to the original asset.
  # This relationship will no longer be valid once the new behaviour actually kicks in.
  class Library < ApplicationRecord
    self.table_name = 'libraries'
    belongs_to :asset, foreign_key: :id
  end

  def up
    Library.transaction do
      Library.where('libraries.name = libraries.id').includes(:asset).find_each do |library|
        if library.asset.nil?
          say "Skipping #{library.id}: no asset"
          next
        end
        library.update!(name: library.asset.external_identifier || "UNBARCODED##{library.id}")
      end
    end
  end

  def down
    Library.find_each do |library|
      library.update!(name: library.id)
    end
  end
end
