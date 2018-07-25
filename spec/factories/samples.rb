# frozen_string_literal: true

FactoryBot.define do
  factory :sample do
    name { generate :sample_name }

    factory :sample_with_well do
      transient do
        library nil
        aliquot { |sample| create(:untagged_aliquout, sample: sample, library: library) }
      end
      sequence(:sanger_sample_id, &:to_s)
      wells { create_list(:well_with_sample_and_plate, 1, aliquots: [aliquot]) }
    end

    factory :sample_with_gender do
      association :sample_metadata, factory: :sample_metadata_with_gender
    end

    factory :sample_with_sanger_sample_id do
      sequence(:sanger_sample_id, &:to_s)
    end
  end

  factory :study_sample do
    study
    sample
  end
end
