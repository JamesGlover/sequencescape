
require 'rails_helper'

describe WorkOrders::Builders::LegacyMxBuilder, type: :model, work_order: true do
  let(:library_creation) { create :request_type }
  let(:multiplexing) { create :request_type }

  let(:parameters) { { request_types: [library_creation.key, multiplexing.key] } }
  subject(:builder) { described_class.new(parameters) }

  let(:work_order) { create :work_order }

  it { is_expected.to respond_to(:build).with(1).argument }

  describe '#build' do
    subject { builder.build(work_order) }
    it { is_expected.to eq true }
  end
end
