
class AssetCreation < ApplicationRecord
  include Uuid::Uuidable
  include Asset::Ownership::ChangesOwner
  extend ModelExtensions::Plate::NamedScopeHelpers

  belongs_to :user
  validates_presence_of :user

  validates_presence_of :parent

  delegate :nil?, to: :parent, prefix: true
  private :parent_nil?

  belongs_to :child_purpose, class_name: 'Purpose'
  validates :child_purpose, presence: true, unless: :multiple_purposes

  before_create :process_children

  def multiple_purposes
    false
  end

  private

  def process_children
    create_children!
    connect_parent_and_children
    record_creation_of_children
  end

  def connect_parent_and_children
    links = children.map { |child| [parent.id, child.id] }
    AssetLink::BuilderJob.create(links)
  end
end
