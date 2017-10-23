require 'rails_helper'

describe WorkOrders::Options, work_order: true do

  let(:options) do
    {
      'static' => {
        'key a' => 'value a',
        'key b' => 'value b'
      },
      'dynamic' => {
        'key c' => {
          'default' => 'value c'
        },
        'key d' => {
          'type' => 'selection',
          'parameters' => {
            'options' => ['yes','no']
          }
        }
      }
    }
  end
  subject(:work_order_options) { described_class.new(options) }

  it { is_expected.to be_a WorkOrders::Options }

  describe '#defaults' do
    subject { work_order_options.defaults }
    it { is_expected.to eq('key a' => 'value a', 'key b' => 'value b', 'key c' => 'value c')}
  end

  describe '#validator' do
    subject(:validator) { work_order_options.validator }
    it { is_expected.to be_a WorkOrders::Options::Validator }

    let(:record) { create :work_order, options: order_options }

    describe 'WorkOrders::Options::Validator#validate' do
      subject { validator.validate(record) }

      context 'when all is good with the world' do
        let(:order_options) { { 'key a' => 'value a', 'key b' => 'value b', 'key c' => 'value d', 'key d' => 'yes' } }
        it { is_expected.to eq true }
      end

      context 'when static fields have changed' do
        let(:order_options) { { 'key a' => 'value x', 'key b' => 'value b', 'key c' => 'value d', 'key d' => 'yes' } }
        it { is_expected.to eq false }
        it 'has errors' do
          subject
          expect(record.errors.full_messages).to include('Key a should be value a')
        end
      end

      context 'when select fields have unrecognised values' do
        let(:order_options) { { 'key a' => 'value x', 'key b' => 'value b', 'key c' => 'value a', 'key d' => 'maybe'  } }
        it { is_expected.to eq false }
        it 'has errors' do
          subject
          expect(record.errors.full_messages).to include('Key d is not an accepted value')
        end
      end
    end
  end
end
