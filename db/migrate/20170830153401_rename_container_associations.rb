class RenameContainerAssociations < ActiveRecord::Migration[4.2]
  def change
    rename_table 'container_associations', 'container_associations_deprecated'
  end
end
