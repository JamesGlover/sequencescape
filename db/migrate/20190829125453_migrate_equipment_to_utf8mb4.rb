# frozen_string_literal: true

# Autogenerated migration to convert equipment to utf8mb4
class MigrateEquipmentToUtf8mb4 < ActiveRecord::Migration[5.1]
  include MigrationExtensions::EncodingChanges

  def change
    change_encoding('equipment', from: 'utf8', to: 'utf8mb4')
  end
end
