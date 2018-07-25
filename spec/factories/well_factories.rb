# frozen_string_literal: true

FactoryBot.define do
  factory :well, aliases: [:empty_well] do
    transient do
      study { build :study }
      project { build :project }
      aliquot_options { |_e, well| { study: study, project: project, receptacle: well } }
      aliquot_factory :untagged_aliquot
      aliquot_count 0
    end
    association(:well_attribute, strategy: :build)
    aliquots { build_list(aliquot_factory, aliquot_count, aliquot_options) }

    factory :untagged_well, parent: :well do
      transient { aliquot_count 1 }
    end

    factory :tagged_well, aliases: [:well_with_sample_and_without_plate] do
      transient do
        aliquot_count 1
        aliquot_factory :tagged_aliquot
      end
    end

    factory :well_with_sample_and_plate do
      transient do
        aliquot_count 1
        aliquot_factory :tagged_aliquot
      end
      map
      plate
    end
  end

  factory :well_attribute do
    concentration       23.2
    current_volume      15

    factory :complete_well_attribute do
      gel_pass            'Pass'
      pico_pass           'Pass'
      sequenom_count      2
    end
  end

  factory :cross_pooled_well, parent: :well do
    map
    plate
    after(:build) do |well|
      als = Array.new(2) do
        {
          sample:  create(:sample),
          study:   create(:study),
          project: create(:project),
          tag:     create(:tag)
        }
      end
      well.aliquots.build(als)
    end
  end

  factory :well_link, class: Well::Link do
    association(:source_well, factory: :well)
    association(:target_well, factory: :well)
    type 'stock'

    factory :stock_well_link
  end

  factory :well_for_qc_report, parent: :well do
    samples { [create(:study_sample, study: study).sample] }
    plate { create(:plate) }
    map { create(:map) }

    after(:create) do |well, evaluator|
      well.aliquots.each { |a| a.update_attributes!(study: evaluator.study) }
    end
  end

  factory :well_for_location_report, parent: :well do
    transient do
      study
      project
    end

    after(:create) do |well, evaluator|
      well.aliquots << build(:untagged_aliquot, receptacle: well, study: evaluator.study, project: evaluator.project)
    end
  end
end
