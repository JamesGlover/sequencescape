FactoryGirl.define do
  factory :work_order_type do
    sequence(:name) { |i| "work_order_#{i}" }
  end

  factory :work_order do
    transient do
      request_count 0
      request_factory :customer_request
    end

    work_order_type
    number 1
    unit_of_measurement 'flowcells'
    state 'pending'
    association(:source_receptacle, factory: :receptacle)
    study
    project

    after(:build) do |work_order, evaluator|
      next if work_order.requests.present?
      work_order.requests = build_list(
        evaluator.request_factory,
        evaluator.request_count,
        asset: evaluator.source_receptacle,
        study: evaluator.study,
        project: evaluator.project
      )
    end
  end
end
