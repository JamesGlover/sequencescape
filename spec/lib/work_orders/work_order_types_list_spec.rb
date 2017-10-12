require 'rails_helper'

describe WorkOrders::WorkOrderTypesList do
  include ConfigurationLoader::Helpers

  let(:folder) { File.join('spec', 'data', 'work_orders') }
  let(:yaml) { load_file(folder, 'work_order_types') }
  subject(:work_order_list) { described_class.new(yaml) }

  it { is_expected.to be_a WorkOrders::WorkOrderTypesList }

  describe '#find' do
    subject { work_order_list.find(name) }

    context 'where the work_order_type exists' do
      let(:name) { 'test_type' }
      it { is_expected.to be_a WorkOrders::WorkOrderType }
    end

    context 'where the work_order_type does not exist' do
      let(:name) { 'not_a_type' }
      it 'raises an exception' do
        expect { subject }.to raise_error(WorkOrders::ConfigNotFound)
      end
    end
  end

  describe '#name_from' do
    context 'when perfectly matching in case' do
      subject { work_order_list.name_from('Test Type') }
      it { is_expected.to eq('test_type') }
    end
    context 'when not matching in case' do
      subject { work_order_list.name_from('TEST Type') }
      it { is_expected.to eq('test_type') }
    end
    context 'when with weird whitespace' do
      subject { work_order_list.name_from(' Test    Type ') }
      it { is_expected.to eq('test_type') }
    end
  end
end
