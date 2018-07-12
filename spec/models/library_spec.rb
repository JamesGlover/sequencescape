# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Library do
  let(:library) { build :library }

  context 'with all associations' do
    subject { build :library }
    it { is_expected.to be_valid }
  end
  context 'without a sample' do
    subject { build :library, sample: nil }
    it { is_expected.to_not be_valid }
  end
  context 'without a request' do
    subject { build :library, request: nil }
    it { is_expected.to_not be_valid }
  end
  context 'without a library_type' do
    subject { build :library, library_type: nil }
    it { is_expected.to_not be_valid }
  end
  context 'without a name' do
    subject { build :library, name: nil }
    it { is_expected.to_not be_valid }
  end
  describe '#library_id' do
    subject { library.legacy_library_id }
    context 'by default' do
      it { is_expected.to eq library.id }
    end
  end
end
