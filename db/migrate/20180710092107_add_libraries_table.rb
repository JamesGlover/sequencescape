# frozen_string_literal: true

# SEQ-675
# https://t117-jira-01.internal.sanger.ac.uk/browse/SEQ-675
# Library has previously existed in Sequencescape as a fairly abstract
# entity. Aliquots have a library_id property, which currently references the
# asset (well or tube) in which tags were applied.
# This table elevates libraries to first class citizens in Sequencescape.
# Existing library data will be migrated into it, maintaining existing
# ids (primary key) and names.
# A library is a sample, prepared for sequencing, and probably labelled
# with one or more tags.
class AddLibrariesTable < ActiveRecord::Migration[5.1]
  def change
    create_table :libraries do |t|
      t.string :name, null: false, uniq: true
      t.references :sample, type: :integer, null: false, foreign_key: true
      # Sadly library types can be null
      # 1) Some older libraries are lacking library type, such as the original pulldown pipeline
      # 2) Library manifests can not set library type until the manifest is uploaded.
      t.references :library_type, type: :integer, null: true, foreign_key: true
      # Ideally this would have a not null constraint, but importing legacy data would likely be tricky
      t.references :request, type: :integer, foreign_key: true
      t.references :parent_library, foreign_key: { to_table: :libraries }, null: true
      t.boolean :delegate_identity, null: false, default: false
      t.timestamps
    end
  end
end
