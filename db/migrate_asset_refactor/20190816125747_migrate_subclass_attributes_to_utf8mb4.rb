# frozen_string_literal: true

# Autogenerated migration to convert subclass_attributes to utf8mb4
class MigrateSubclassAttributesToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('subclass_attributes', from: 'latin1', to: 'utf8mb4')
  end
end
