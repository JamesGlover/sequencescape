# frozen_string_literal: true

# Autogenerated migration to convert stamps to utf8mb4
class MigrateStampsToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('stamps', from: 'utf8', to: 'utf8mb4')
  end
end
