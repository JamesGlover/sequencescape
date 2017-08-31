class RenameContainerAssociations < ActiveRecord::Migration
  def change
    rename_table 'container_associations', 'container_associations_deprecated'
  end
end
