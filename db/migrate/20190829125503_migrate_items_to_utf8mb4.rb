# frozen_string_literal: true

# Autogenerated migration to convert items to utf8mb4
class MigrateItemsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('items', from: 'latin1', to: 'utf8mb4')
  end
end
