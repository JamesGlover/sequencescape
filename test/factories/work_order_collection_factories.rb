FactoryGirl.define do
  factory :work_order_collection do
    sequence(:name) { |i| "work_order_collection_#{i}" }

    transient do
      work_order_count 0
    end

    after(:build) do |work_order_collection, evaluator|
      work_order_collection.work_orders = build_list(:work_order, evaluator.work_order_count)
    end
  end
end
