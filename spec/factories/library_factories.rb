# frozen_string_literal: true

FactoryBot.define do
  factory :library do
    sequence(:name) { |i| "Library #{i}" }
    sample
    request
    library_type
  end
end
