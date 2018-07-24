# frozen_string_literal: true

# Basic import which assumes our data is all sensible.
class ImportSimpleLibraryData < ActiveRecord::Migration[5.1]
  def up
    # Raw SQL to generate the initial library import. Has the following limitations and assumptions:
    # 1) Assumption: libraries will only ever have one library_type/sample
    # 2) Limitation: Display names will not be set
    # 3) Limitation: Request id will only be imported for the newest aliquots
    ActiveRecord::Base.connection.execute('
      INSERT INTO libraries (id, `name`, library_type_id, sample_id, request_id, created_at, updated_at)
      SELECT
        library_id AS id,
        library_id AS `name`,
        MIN(library_types.id) AS library_type_id,
        MIN(aliquots.sample_id) AS sample_id,
        MIN(aliquots.request_id) AS request_id,
        MIN(aliquots.created_at) AS created_at,
        MAX(aliquots.updated_at) AS updated_at
        FROM aliquots
      LEFT JOIN library_types ON library_types.name = aliquots.library_type
      WHERE library_id IS NOT NULL AND library_type IS NOT NULL
      GROUP BY library_id')
  end

  def down
    Library.delete_all
  end
end
