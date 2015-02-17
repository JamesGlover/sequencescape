#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class ContainerAssociation < ActiveRecord::Base
  #We don't define the class, so will get an error if being used directly
  # in fact , the class need to be definend otherwise, eager loading through doesn't work
  belongs_to :container , :class_name => "Asset"
  belongs_to :content , :class_name => "Well", :inverse_of => :container_association

  before_validation :ensure_position_copied
  def ensure_position_copied
    self.position_id = content.map_id
    true
  end
  private :ensure_position_copied

  validates_presence_of :position_id
  validates_uniqueness_of :position_id, :scope => :container_id

  # NOTE: This was originally on the content asset but this causes massive performance issues.
  # It causes the plate and it's metadata to be loaded for each well, which would be cached if
  # it were not for inserts/updates being performed.  I'm disabling this as it should be caught
  # in tests and we've not seen it in production.
  #
#  # We check if the parent has already been saved. if not the saving will not work.
#  before_save do |content|
#    container = content.container
#    raise RuntimeError, "Container should be saved before saving #{self.inspect}" if container && container.new_record?
#  end

  module Extension
    def contains(content_name, options = {}, &block)
      class_name = content_name ? content_name.to_s.classify : Asset.name
      has_many :container_associations, :foreign_key => :container_id, :inverse_of => :container
      has_many :contents, options.merge(:class_name => class_name, :through => :container_associations)
      has_many(content_name, options.merge(:class_name => class_name, :through => :container_associations, :source => :content)) do
        # Provide bulk importing abilities.  Inside a transaction we can guarantee that the information in the DB is
        # consistent from our perspective.  In other words, we can bulk insert the records and then reload them, limited
        # by their count, to obtain the IDs.
        #
        # WARNING: We have to be extremely careful about how to select the appropriate data from the bulk insert as
        # the DB can choose to ignore the ordering. To get round this we perform one query in the correct order and
        # then limit it, rather than doing these two steps together.
        line = __LINE__ + 1
        class_eval(%Q{
          def import(records)
            ActiveRecord::Base.transaction do

              records.map(&:save!)

              sub_query = #{class_name}.send(:construct_finder_sql, :select => 'id, map_id', :order => 'id DESC')
              records   = #{class_name}.connection.select_all(%Q{SELECT id, map_id FROM (\#{sub_query}) AS a LIMIT \#{records.size}})
              attach(records)
              post_import(records.map { |r| [proxy_owner.id, r['id']] })
            end
          end
        }, __FILE__, line)

        def attach(records)
          ActiveRecord::Base.transaction do
            records.each { |r| ContainerAssociation.create!(:container_id => proxy_owner.id, :content_id => r['id'], :position_id => r['map_id']) }
          end
        end

        # Sometimes we need to do things after importing the contained records.  This is the callback that should be
        # overridden by the block passed.
        def post_import(_)
          # Does nothing by default
        end

        def connect(content)
          ContainerAssociation.create!(:container => proxy_owner, :content => content)
          post_connect(content)
        end
        private :connect

        class_eval(&block) if block_given?
      end

      named_scope :"include_#{content_name}", :include => :contents  do
        def to_include
          [:contents]
        end

        def with(subinclude)
          scoped(:include => { :contents => subinclude })
        end
      end
    end

    def contained_by(container_name, &block)
      class_name = container_name.to_s.singularize.capitalize
      has_one :container_association, :foreign_key => :content_id, :inverse_of => :content
      has_one :container, :class_name => class_name, :through => :container_association
      has_one(container_name, :class_name => class_name, :through => :container_association, :source => :container, &block)

      define_method(:"#{container_name}=") do |container|
        # We define a custom method so that we don't need to reload the content object
        raise ActiveRecord::AssociationTypeMismatch unless container.is_a?(class_name.constantize)
        ContainerAssociation.create!(:container=>container,:content=>self)
      end
      #delegate :location, :to => :container
    end
  end
end
