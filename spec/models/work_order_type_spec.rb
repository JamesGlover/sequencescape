require 'rails_helper'

describe WorkOrderType, work_order: true do
  subject(:work_order_type) { build :work_order_type, name: name }

  context 'with a name' do
    let(:name) { 'test_type' }

    context 'which doesn\'t clash' do
      it { is_expected.to be_valid }
    end

    context 'which already exists' do
      before { create :work_order_type, name: name }
      it { is_expected.not_to be_valid }
    end

    describe '#spec' do
      before(:all) do
        WorkOrders.configure do |config|
          config.folder = File.join('spec', 'data', 'work_orders')
          config.load!
        end
      end

      subject { work_order_type.spec }
      it { is_expected.to be_a WorkOrders::WorkOrderType }
      it 'is the correct spec' do
        expect(subject.name).to eq(name)
      end

      after(:all) { WorkOrders.reset! }
    end
  end

  context 'without an name' do
    let(:name) { nil }
    it { is_expected.not_to be_valid }
  end

  context 'with a name with spaces' do
    let(:name) { 'invalid name' }
    it { is_expected.not_to be_valid }
  end

  context 'with a name with capitals' do
    let(:name) { 'Invalid_name' }
    it { is_expected.not_to be_valid }
  end

  context 'with a name with symbols' do
    let(:name) { 'Invalid@name' }
    it { is_expected.not_to be_valid }
  end
end
