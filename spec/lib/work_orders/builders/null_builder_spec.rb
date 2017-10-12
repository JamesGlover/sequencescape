
require 'rails_helper'

describe WorkOrders::Builders::NullBuilder, type: :model do
  let(:configuration) { described_class.new }

  it { is_expected.to respond_to(:build).with(1).argument }
end
