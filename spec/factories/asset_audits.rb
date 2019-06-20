# frozen_string_literal: true

FactoryBot.define do
  factory(:asset_audit) do
    message { 'Some message' }
    key { 'some_key' }
    created_by { 'abc123' }
    witnessed_by { 'jane' }
    association(:asset, factory: :labware)
  end
end
