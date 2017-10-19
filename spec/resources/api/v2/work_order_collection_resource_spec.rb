require 'rails_helper'
# require './app/resources/api/v2/work_order_resource'

RSpec.describe Api::V2::WorkOrderCollectionResource, type: :resource, work_order: true do
  subject { described_class.new(work_order_collection, {}) }
  let(:work_order_collection) { create(:work_order_collection, work_order_count: 2) }

  it { is_expected.to have_attribute :name }
  it { is_expected.to have_updatable_field(:name) }
  it { is_expected.to have_many(:work_orders).with_class_name('WorkOrder') }
end
