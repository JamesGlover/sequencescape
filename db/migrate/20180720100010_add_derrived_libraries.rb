# frozen_string_literal: true

# In a few cases we have library ids shared by assets with different
# library types, or even samples.
# As this data has passed to customers we want to avoid changing it unexpectedly.
class AddDerrivedLibraries < ActiveRecord::Migration[5.1]
  def up
    Aliquot.transaction do
      Aliquot.joins([
        'left join libraries ON libraries.id = aliquots.library_id',
        'left join library_types ON library_types.name = aliquots.library_type'
      ]).where(
        'libraries.sample_id != aliquots.sample_id OR libraries.library_type_id != library_types.id'
      ).select(
        ['MIN(aliquots.id) AS id',
         'aliquots.sample_id',
         'aliquots.library_id',
         'aliquots.library_type',
         'library_types.id AS library_type_id',
         'libraries.name AS library_name']
      ).group(
        'aliquots.library_id, aliquots.library_type'
      ).find_each do |aliquot|
        say "Repairing #{aliquot.id}"
        new_name = "#{aliquot.library_name}-derived"
        new_lib = Library.create!(
          name: new_name,
          sample_id: aliquot.sample_id,
          library_type_id: aliquot.library_type_id,
          parent_library_id: aliquot.library_id,
          delegate_identity: true
        )
        # rubocop:disable Rails/SkipsModelValidations
        # We are prioritising performance here.
        Aliquot.where(
          library_id: aliquot.library_id,
          sample_id: aliquot.sample_id,
          library_type: aliquot.library_type
        ).update_all(library: new_lib)
        # rubocop:enable Rails/SkipsModelValidations
      end
    end
  end

  def down
    Aliquot.transaction do
      Aliquot.joins(:library).where(library: { delegate_identity: true }).find_each do |ali|
        ali.update!(library_id: ali.library.parent_library_id)
      end
      Library.where(delegate_identity: true).delete_all
    end
  end
end
