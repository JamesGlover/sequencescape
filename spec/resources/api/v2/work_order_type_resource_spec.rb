require 'rails_helper'
require './app/resources/api/v2/work_order_resource'

RSpec.describe Api::V2::WorkOrderTypeResource, type: :resource, work_order: true do
  shared_examples_for 'a work order resource' do
    subject { described_class.new(work_order_type, {}) }

    it { is_expected.to have_attribute :friendly_name }
    it { is_expected.to have_attribute :name }
    it { is_expected.to have_attribute :unit_of_measurement }
    it { is_expected.to have_attribute :options }

    it { is_expected.to_not have_updatable_field :friendly_name }
    it { is_expected.to_not have_updatable_field :name }
    it { is_expected.to_not have_updatable_field :unit_of_measurement }
    it { is_expected.to_not have_updatable_field :options }


    it 'renders relevant options' do
      expect(subject.options).to eq(expected_options)
    end

  end

  context 'a basic work_order_type' do
    let(:expected_options) do
      { 'static' => {}, 'dynamic' => {} }
    end

    let(:config) do
      {
        friendly_name: 'Test Type',
        builder: {
          builder_class: 'TestBuilder',
          params: { 'test_param' => 'pass' }
        },
        unit_of_measurement: 'flowcells',
        options: expected_options
      }
    end

    let(:work_order_type) { create(:work_order_type, work_order_config: config) }
    it_behaves_like 'a work order resource'
  end
end
