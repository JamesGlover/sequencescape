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
  # Ideally would be required
  context 'without a request' do
    subject { build :library, request: nil }
    it { is_expected.to be_valid }
  end
  # Library Manifests used to set library id upfront,
  # but we could possibly generate libraries on upload to
  # allow us to enforce this.
  context 'without a library_type' do
    subject { build :library, library_type: nil }
    it { is_expected.to be_valid }
  end
  context 'without a name' do
    let(:source_asset) { create :untagged_well }
    let(:request) { create :library_request, asset: source_asset }
    subject { build :library, name: nil, request: request }
    it 'generates a name based on the asset' do
      subject.valid?
      expect(subject.name).to eq("#{source_asset.external_identifier}##{request.id}")
    end
  end
  describe '#library_id' do
    subject { library.legacy_library_id }
    context 'by default' do
      it { is_expected.to eq library.id }
    end
  end

  context 'for a limited time only' do
    # These tests are to reduce the amount of downtime required
    # They can be removed once 20180720100019 has been run in production
    context 'when library id matches name' do
      let(:library) { build :library }
      it 'Falls back to the asset with the same id for a name' do
        library.save!
        library.name = library.id
        library.save!
        asset = create :library_tube, id: library.id
        expect(library.name).to eq(asset.external_identifier)
      end
    end
  end

  context 'with a parent' do
    let(:parent_library) { create :library }
    let(:library) { build :library, parent_library: parent_library, delegate_identity: delegate_identity }

    context 'delegating identity' do
      let(:delegate_identity) { true }
      describe '#legacy_library_id' do
        subject { library.legacy_library_id }
        it { is_expected.to eq parent_library.id }
      end
      describe '#external_identifier' do
        subject { library.external_identifier }
        it { is_expected.to eq parent_library.name }
      end
    end

    context 'not delegating identity' do
      let(:delegate_identity) { false }
      describe '#legacy_library_id' do
        subject { library.legacy_library_id }
        it { is_expected.to eq library.id }
      end
      describe '#external_identifier' do
        subject { library.external_identifier }
        it { is_expected.to eq library.name }
      end
    end
  end
end
