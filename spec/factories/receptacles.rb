# frozen_string_literal: true

FactoryBot.define do
  factory :receptacle do
    factory :receptacle_with_sample_tube do
      association(:labware, factory: :sample_tube)
    end
  end
end
