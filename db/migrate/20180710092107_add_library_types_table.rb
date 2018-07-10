# frozen_string_literal: true

# SEQ-675
# https://t117-jira-01.internal.sanger.ac.uk/browse/SEQ-675
# Library has previously existed in Sequencescape as a fairly abstract
# entity. Aliquots have a library_id property, which currently references the
# asset (well or tube) in which tags were applied.
# This table elevates libraries to first class citizens in Sequencescape.
# Existing library data will be migrated into it, maintaining existing
# ids (primary key) and names.
class AddLibraryTypesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :library_types do |t|
      t.string :name, null: false, uniq: true
      t.references :sample, null: false, foreign_key: true
      # Ideally this would have a not null constraint, but importing legacy data would likely be tricky
      t.references :request, foreign_key: true
      t.timestamps
    end
  end
end
