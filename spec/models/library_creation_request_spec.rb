# frozen_string_literal: true

require 'rails_helper'

# Base library creation class used for the majority of our library creation pipelines.
RSpec.describe LibraryCreationRequest, type: :model do
  context '#create' do
    let(:library_request) { build :library_creation_request, asset: source }
    context 'with a single sample' do
      let(:source) { create :sample_tube }
      it 'generates a library' do
        library_request.save!
        expect(library_request.library).to be_a Library
      end
      it 'generates a useful name based on the source asset and request_id' do
        library_request.save!
        expect(library_request.library.name).to eq("#{source.external_identifier}##{library_request.id}")
      end
    end
    context 'with an empty tube' do
      # If library requests are downstream in the request graph, then the source asset
      # may not have a sample in it, or may not even exist at all. However this situation shouldn't
      # occur with our current templates.
      # In the future it may be necessary to re-engineer things to support this scenario,
      # but currently we want to blow up messily, to ensure that this situation gets handled correctly
      # when it occurs.
      let(:source) { build :empty_sample_tube }
      it 'does not generate a library' do
        expect(library_request.save).to be false
      end
    end
    context 'with no asset but an upstream request' do
      let(:upstream_library_request) { create :library_creation_request, asset: source }
      let(:library_request) { build :library_creation_request, asset: nil, upstream_requests_at_build: [upstream_library_request] }
      let(:source) { create :sample_tube }
      it 'generates a library' do
        library_request.save!
        expect(library_request.library).to be_a Library
      end
      it 'generates a useful name based on the original library and request_id' do
        library_request.save!
        expect(library_request.library.name).to eq("#{source.external_identifier}##{library_request.id}")
      end
    end
    context 'with a multi-sample tube' do
      # Theoretically we may end up making libraries from already pooled samples.
      # This would necessitate changing has_one to has_many, but otherwise shouldn't
      # be too tricky. But until then we blow up messily, as otherwise we risk generating
      # just a single library without anyone realising.
      let(:source) { build :multiplexed_library_tube, sample_count: 2 }
      it 'does not generate a library' do
        expect(library_request.save).to be false
      end
    end
  end
  context '#aliquot_attributes' do
    let(:library_creation_request) { create :library_creation_request }
    it 'sets sensible aliquot attributes' do
      expect(library_creation_request.aliquot_attributes).to eq(
        study_id: library_creation_request.initial_study_id,
        project_id: library_creation_request.initial_project_id,
        library_type: 'Standard',
        insert_size: library_creation_request.insert_size,
        request_id: library_creation_request.id,
        library_id: library_creation_request.library.id
      )
    end
  end
end
