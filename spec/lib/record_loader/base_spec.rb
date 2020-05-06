# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/plate_purpose_loader'

RSpec.describe RecordLoader::Base, type: :model, loader: true do
  subject(:record_loader) do
    allow(ENV).to receive(:fetch).with('WIP', '').and_return(wip_flags)
    custom_subclass.new(options)
  end

  let(:custom_subclass) do
    # RecordLoader::Base is not used directly, but as a subclass
    Class.new(described_class) do
      def create_or_update!(*args)
        @create_or_update_called ||= []
        @create_or_update_called << args
      end

      def create_or_update_called
        @create_or_update_called || []
      end
    end
  end

  let(:options) { { directory: test_directory, dev: dev, files: selected_files } }
  let(:test_directory) { Rails.root.join('spec/data/record_loader/base') }
  let(:wip_flags) { '' }

  describe '#create' do
    setup { subject.create! }

    context 'when not in the development environment' do
      let(:dev) { false }

      context 'with no files specified' do
        let(:selected_files) { nil }

        it 'calls create or update for non dev files' do
          expect(record_loader.create_or_update_called).to have(4).items
        end
      end

      context 'with a specific file specified' do
        let(:selected_files) { ['001_example'] }

        it 'calls create or update for the selected file files' do
          expect(record_loader.create_or_update_called).to have(2).items
        end
      end

      context 'with a dev file specified' do
        let(:selected_files) { ['002_example'] }

        it 'calls create or update for dev file' do
          expect(record_loader.create_or_update_called).to have(2).items
        end
      end

      context 'with a wip file specified' do
        let(:selected_files) { ['003_example'] }

        it 'calls create or update for dev file' do
          expect(record_loader.create_or_update_called).to have(2).items
        end
      end

      context 'when WIP flags are set' do
        let(:wip_flags) { '003_example,dummy_flag' }
        let(:selected_files) { nil }

        it 'calls create or update for wip file' do
          expect(record_loader.create_or_update_called).to have(6).items
        end
      end
    end

    context 'when in the development environment' do
      let(:options) { { directory: test_directory, dev: true } }

      it 'calls create or update for dev files in addition' do
        expect(record_loader.create_or_update_called).to have(6).items
      end
    end
  end
end
