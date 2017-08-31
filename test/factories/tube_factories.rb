require 'factory_girl'

FactoryGirl.define do
  factory :tube do
    name { generate :asset_name }
    association(:purpose, factory: :tube_purpose)
  end

  factory :empty_sample_tube, class: SampleTube do
    name                { generate :asset_name }
    descriptors         []
    descriptor_fields   []
    qc_state            ''
    barcode
    purpose { Tube::Purpose.standard_sample_tube }
  end

  factory :sample_tube, parent: :empty_sample_tube do
    transient do
      sample { create(:sample) }
      study { create(:study) }
      project { create(:project) }
    end

    after(:create) do |sample_tube, evaluator|
      create_list(:untagged_aliquot, 1, sample: evaluator.sample, receptacle: sample_tube.receptacle, study: evaluator.study, project: evaluator.project)
    end

    factory :sample_tube_with_sanger_sample_id do
      transient do
        sample { create(:sample_with_sanger_sample_id) }
      end
    end
  end

  factory :qc_tube do
    barcode
  end

  factory :multiplexed_library_tube do
    name    { |_a| generate :asset_name }
    purpose { Tube::Purpose.standard_mx_tube }
  end

  factory :pulldown_multiplexed_library_tube do
    name { |_a| generate :asset_name }
  end

  factory :stock_multiplexed_library_tube do
    name    { |_a| generate :asset_name }
    purpose { Tube::Purpose.stock_mx_tube }

    factory :new_stock_multiplexed_library_tube do |_t|
      purpose { |a| a.association(:new_stock_tube_purpose) }
    end
  end

  factory(:empty_library_tube, class: LibraryTube) do
    qc_state ''
    name     { generate :asset_name }
    purpose  { Tube::Purpose.standard_library_tube }
  end

  factory(:library_tube, parent: :empty_library_tube) do
    after(:build) do |tube, evaluator|
      tube.receptacle = build(:receptacle_with_sample, map_id: 1)
    end
  end

 factory(:library_tube_with_barcode, parent: :empty_library_tube) do
    sequence(:barcode) { |i| i }
    after(:create) do |library_tube|
      library_tube.receptacle.aliquots.create!(sample: create(:sample_with_sanger_sample_id), library_type: 'Standard')
    end
 end

  factory(:tagged_library_tube, class: LibraryTube) do
    transient do
      tag_map_id 1
    end

    after(:create) do |library_tube, evaluator|
      library_tube.receptacle.aliquots << build(:tagged_aliquot, tag: create(:tag, map_id: evaluator.tag_map_id), receptacle: library_tube.receptacle)
    end
  end

  factory :pac_bio_library_tube do
   # association(:receptacle, factory: :pac_bio_library_tube_receptacle)
    barcode
  end

  # A library tube is created from a sample tube through a library creation request!
  factory(:full_library_tube, parent: :library_tube) do
    after(:create) { |tube| create(:library_creation_request, target_asset: tube.receptacle) }
  end

  factory :broken_multiplexed_library_tube, parent: :multiplexed_library_tube

  factory :stock_library_tube do
    name     { |_a| generate :asset_name }
    purpose  { Tube::Purpose.stock_library_tube }
  end
end
