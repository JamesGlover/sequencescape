require 'rails_helper'

describe WorkOrders::WorkOrderType, work_order: true do
  include ConfigurationLoader::Helpers

  let(:folder) { File.join('spec', 'data', 'work_orders') }
  let(:yaml) { load_file(folder, 'work_order_types') }
  let(:name) { 'test_type' }
  subject(:work_order) { described_class.new(name, yaml[name]) }

  it { is_expected.to be_a WorkOrders::WorkOrderType }

  describe '#friendly_name' do
    subject { work_order.friendly_name }

    context 'when configured' do
      let(:name) { 'test_type' }
      it { is_expected.to eq 'Test Type' }
    end

    context 'when not-configured' do
      let(:name) { 'auto_friendly_name' }
      it { is_expected.to eq 'Auto friendly name' }
    end
  end

  describe '#builder' do
    subject { work_order.builder }
    # We use a test builder class here.
    it { is_expected.to be_a WorkOrders::Builders::TestBuilder }
    it { is_expected.to have_attributes(test_param: 'pass') }
  end
end
