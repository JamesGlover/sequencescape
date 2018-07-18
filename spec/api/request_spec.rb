# frozen_string_literal: true

require 'rails_helper'
require 'support/barcode_helper'
require_relative 'shared_examples'

describe '/api/1/request-uuid' do
  subject { '/api/1/' + uuid }

  let(:authorised_app) { create :api_application }
  let(:uuid) { request.uuid }

  let(:request_type_name) { request.request_type.name }
  let(:root) { 'request' }
  let(:source_asset_name) { 'Source Asset' }
  let(:target_asset_name) { 'Target Asset' }

  let(:response_body) do
    {
      "#{root}": {
        "actions": {
          "read": "http://www.example.com/api/1/#{uuid}"
        },

        "uuid": uuid,
        "state": 'pending',

        "type": request_type_name,
        "fragment_size": {
          "from": fragment_size_from,
          "to": fragment_size_to
        },

        "source_asset": {
          "type": source_asset_type,
          "name": source_asset_name
        },
        "target_asset": {
          "type": target_asset_type,
          "name": target_asset_name
        }
      }
    }.to_json
  end

  context 'A sequencing request' do
    let(:asset) { create :multiplexed_library_tube, name: source_asset_name }
    let(:target_asset) { create :lane, name: target_asset_name }
    let(:request) { create :sequencing_request, asset: asset, target_asset: target_asset }
    let(:root) { 'sequencing_request' }
    # Sequencing requests don't convert fragment size to an integer.
    # We can probably fix this without issue, but not 100% sure.
    let(:fragment_size_from) { '1' }
    let(:fragment_size_to) { '21' }
    let(:source_asset_type) { 'multiplexed_library_tubes' }
    let(:target_asset_type) { 'lanes' }
    it_behaves_like 'an API/1 GET endpoint'
  end

  context 'A library_creation request' do
    let(:request) { create :library_request, target_asset: create(:well) }
    let(:source_asset_name) { nil }
    let(:target_asset_name) { nil }
    let(:fragment_size_from) { 1 }
    let(:fragment_size_to) { 20 }
    let(:source_asset_type) { 'wells' }
    let(:target_asset_type) { 'wells' }
    it_behaves_like 'an API/1 GET endpoint'
  end

  let(:response_code) { 200 }
end

describe '/api/1/requests' do
  subject { '/api/1/requests' }
  let(:authorised_app) { create :api_application }
  let(:request) { create :library_request, target_asset: create(:well) }
  let(:request_type_name) { request.request_type.name }
  let(:source_asset_name) { nil }
  let(:target_asset_name) { nil }
  let(:fragment_size_from) { 1 }
  let(:fragment_size_to) { 20 }
  let(:source_asset_type) { 'wells' }
  let(:target_asset_type) { 'wells' }
  it_behaves_like 'an API/1 GET endpoint'

  before { request }

  let(:response_body) do
    {
      "actions": {
        "read": 'http://www.example.com/api/1/requests/1',
        "first": 'http://www.example.com/api/1/requests/1',
        "last": 'http://www.example.com/api/1/requests/1'
      },
      "requests": [
        {
          "actions": {
            "read": "http://www.example.com/api/1/#{request.uuid}"
          },

          "uuid": request.uuid,
          "state": 'pending',

          "type": request_type_name,
          "fragment_size": {
            "from": fragment_size_from,
            "to": fragment_size_to
          },

          "source_asset": {
            "type": source_asset_type,
            "name": source_asset_name
          },
          "target_asset": {
            "type": target_asset_type,
            "name": target_asset_name
          }
        }
      ]
    }.to_json
  end

  let(:response_code) { 200 }

  it_behaves_like 'an API/1 GET endpoint'
end
