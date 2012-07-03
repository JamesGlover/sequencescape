class SetPositionOnContainerAssociationsFromWells < ActiveRecord::Migration
  class ContainerAssociation < ActiveRecord::Base
    set_table_name('container_associations')
    belongs_to :well, :foreign_key => :content_id, :class_name => 'SetPositionOnContainerAssociationsFromWells::Well'

    def connect_position!
      update_attributes!(:position_id => well.map_id)
    end
  end

  class Well < ActiveRecord::Base
    set_table_name('assets')
    default_scope(:conditions => ['sti_type=?', 'Well'])
  end

  def self.up
    ActiveRecord::Base.transaction do
      ContainerAssociation.find_each(:include => :well) do |association|
        association.connect_position!
      end
    end
  end

  def self.down
    # Nothing to do here, will drop in next migration
  end
end
