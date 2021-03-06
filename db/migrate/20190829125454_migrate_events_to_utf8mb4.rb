# frozen_string_literal: true

# Autogenerated migration to convert events to utf8mb4
class MigrateEventsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('events', from: 'latin1', to: 'utf8mb4')
  end
end
