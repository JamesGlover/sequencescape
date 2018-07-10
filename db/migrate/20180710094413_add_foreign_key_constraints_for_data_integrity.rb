# frozen_string_literal: true

# We have a large number of associations in Sequencescape, most of which don't
# have foreign key constraints. This migration add constraints to some existing
# associations where there are no current data integrity issues in production.
class AddForeignKeyConstraintsForDataIntegrity < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key 'aliquots', 'samples'
  end
end
