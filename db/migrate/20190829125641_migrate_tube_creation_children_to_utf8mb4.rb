# frozen_string_literal: true

# Autogenerated migration to convert tube_creation_children to utf8mb4
class MigrateTubeCreationChildrenToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('tube_creation_children', from: 'latin1', to: 'utf8mb4')
  end
end
