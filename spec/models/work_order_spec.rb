require 'rails_helper'

describe WorkOrder, work_order: true do
  subject(:work_order) { build :work_order, work_order_type: work_order_type }

  context 'with a work_order_type' do
    let(:work_order_type) { create :work_order_type }
    it { is_expected.to be_valid }
  end

  context 'without an work_order_type' do
    let(:work_order_type) { nil }
    it { is_expected.not_to be_valid }
  end

  context 'with requests' do
    let(:requests) { build_list(:request, 2) }
    let(:work_order) { build :work_order, requests: requests }

    describe '#state=' do
      before { work_order.state = 'passed' }
      it 'update the associated requests' do
        requests.each do |request|
          expect(request.state).to eq('passed')
        end
      end
    end
  end

  describe WorkOrder::Factory do
    let(:submission) { create :submission, requests: requests }
    let(:request_type) { create :request_type }
    let(:study) { create :study }
    let(:project) { create :project }
    let(:options) { { read_length: 200 } }

    before do
      create :work_order_type, name: request_type.key
    end

    let(:requests_set_a) { create_list(:library_request, 3, asset: create(:well), request_type: request_type, study: study, project: project) }
    let(:requests) { requests_set_a + requests_set_b }
    subject(:factory) { described_class.new(submission, unit_of_measurement: :flowcells) }

    context 'where request types match' do
      let(:requests_set_b) { create_list(:library_request, 3, asset: create(:well), request_type: request_type, study: study, project: project) }
      let(:expected_options) do
        { 'fragment_size_required_from' => '1', 'fragment_size_required_to' => '20', 'library_type' => 'Standard', 'read_length' => 76 }
      end

      it { is_expected.to be_valid }

      it 'generates a work_order per asset' do
        work_orders = subject.create_work_orders!
        expect(work_orders).to be_an Array
        expect(work_orders.length).to eq 2
        actual_request_groups = work_orders.map { |wo| wo.requests.to_a }.sort
        expected_request_groups = [requests_set_a.to_a, requests_set_b.to_a].sort
        expect(actual_request_groups).to eq(expected_request_groups)
      end

      it 'sets the work_order_type on each work order' do
        work_orders = subject.create_work_orders!
        work_orders.each do |work_order|
          expect(work_order.work_order_type.name).to eq(request_type.key)
        end
      end

      it 'imports the request attributes' do
        work_orders = subject.create_work_orders!
        work_orders.each do |work_order|
          expect(work_order.study).to eq(study)
          expect(work_order.project).to eq(project)
          expect(work_order.options).to eq(expected_options)
        end
      end

      it 'sets the source_receptacle' do
        work_orders = subject.create_work_orders!
        actual_receptacles = work_orders.map(&:source_receptacle).sort
        expected_receptacles = [ requests_set_a.first.asset,requests_set_b.first.asset] .sort
        expect(actual_receptacles).to eq(expected_receptacles)
      end

      it 'sets the state on each work order' do
        work_orders = subject.create_work_orders!
        expect(work_orders.first.state).to eq('pending')
      end
    end

    context 'where request types clash' do
      let(:requests_set_b) { create_list(:request, 3, asset: create(:well)) }
      it { is_expected.not_to be_valid }
    end
  end
end
