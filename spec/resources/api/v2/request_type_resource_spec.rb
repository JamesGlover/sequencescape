# frozen_string_literal: true

require 'rails_helper'
require './app/resources/api/v2/request_type_resource'

RSpec.describe Api::V2::RequestTypeResource, type: :resource do
  subject { described_class.new(resource_model, {}) }

  let(:resource_model) { create :request_type }

  # Test attributes
  it 'works', :aggregate_failures do
    expect(subject).to have_attribute :uuid
    expect(subject).to have_attribute :name
    expect(subject).to have_attribute :key
    expect(subject).to have_attribute :for_multiplexing
    expect(subject).not_to have_updatable_field(:id)
    expect(subject).not_to have_updatable_field(:uuid)
    expect(subject).not_to have_updatable_field(:name)
    expect(subject).not_to have_updatable_field(:key)
    expect(subject).not_to have_updatable_field(:for_multiplexing)
  end

  # Updatable fields
  # eg. it { is_expected.to have_updatable_field(:state) }

  # Filters
  # eg. it { is_expected.to filter(:order_type) }

  # Associations
  # eg. it { is_expected.to have_many(:samples).with_class_name('Sample') }

  # Custom method tests
  # Add tests for any custom methods you've added.
end
