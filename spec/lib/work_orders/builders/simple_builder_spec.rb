
require 'rails_helper'

describe WorkOrders::Builders::SimpleBuilder, type: :model, work_order: true do
  let(:library_creation) { create :grid_ion_request_type }

  let(:parameters) { { request_type: library_creation.key }  }
  subject(:builder) { described_class.new(parameters) }

  let(:work_order) { create :work_order, number: 2, unit_of_measurement: :flowcells, options: { data_type: 'basecalls', library_type: 'Rapid' } }

  it { is_expected.to respond_to(:build).with(1).argument }

  describe '#build' do
    subject { builder.build(work_order) }
    it { is_expected.to eq true }

    it 'builds requests' do
      expect { subject }.to change { work_order.requests.count }.by (2)
    end

    it 'sets the request metadata' do
      work_order.requests.each do |r|
        expect(t.request_metadata.data_type).to eq
      end
    end
  end
end
