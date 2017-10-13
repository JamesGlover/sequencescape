
require 'rails_helper'

describe WorkOrders::Builders::LegacyMxBuilder, type: :model do
  let(:library_creation) { create :request_type }

  let(:parameters) { { request_type: library_creation.key }  }
  subject(:builder) { described_class.new(parameters) }

  let(:work_order) { create :work_order }

  it { is_expected.to respond_to(:build).with(1).argument }

  describe '#build' do
    subject { builder.build(work_order) }
    it { is_expected.to eq true }

    it 'builds requests' do
    end
  end
end
