# frozen_string_literal: true

require 'rails_helper'

describe 'WorkOrderCollections API', with: :api_v2, work_order: true do

  describe 'index' do
    before do
      create_list :work_order_collection, 5
    end

    it 'sends a list of work_orders' do
      api_get '/api/v2/work_order_collections'
      # test for the 200 status-code
      expect(response).to have_http_status(:success)
      # check to make sure the right amount of messages are returned
      expect(json['data'].length).to eq(5)
    end
  end

  describe 'create' do
    let(:payload) do
      {
        "data":{
          "type":"work_order_collections",
          "attributes":{"name":"Test"}
        }
      }
    end
    it 'allows creation of work_orders' do
      api_post '/api/v2/work_order_collections', payload
      expect(response).to have_http_status(:success)
    end
  end
end
