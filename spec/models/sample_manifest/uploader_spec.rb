# frozen_string_literal: true

require 'rails_helper'
require 'pry'

RSpec.describe SampleManifest::Uploader, type: :model, sample_manifest_excel: true do
  before(:all) do
    SampleManifestExcel.configure do |config|
      config.folder = File.join('spec', 'data', 'sample_manifest_excel')
      config.tag_group = 'My Magic Tag Group'
      config.load!
    end
  end

  let(:test_file) { 'test_file.xlsx' }
  let(:user) { create :user }

  it 'will not be valid without a filename' do
    expect(SampleManifest::Uploader.new(nil, SampleManifestExcel.configuration, user, false)).to_not be_valid
  end

  it 'will not be valid without some configuration' do
    download = build(:test_download_tubes, manifest_type: 'tube_library_with_tag_sequences', columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file)
    expect(SampleManifest::Uploader.new(test_file, nil, user, false)).to_not be_valid
  end

  it 'will not be valid without a tag group' do
    SampleManifestExcel.configuration.tag_group = nil
    download = build(:test_download_tubes, manifest_type: 'tube_library_with_tag_sequences', columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file)
    expect(SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)).to_not be_valid
    SampleManifestExcel.configuration.tag_group = 'My Magic Tag Group'
  end

  it 'will not be valid without a user' do
    download = build(:test_download_tubes, columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
    download.save(test_file)
    expect(SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, nil, false)).to_not be_valid
  end

  context 'when checking uploads' do
    it 'will upload a valid 1d tube sample manifest' do
      broadcast_events_count = BroadcastEvent.count
      download = build(:test_download_tubes, manifest_type: 'tube_full', columns: SampleManifestExcel.configuration.columns.tube_full.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid library tube with tag sequences sample manifest' do
      broadcast_events_count = BroadcastEvent.count
      download = build(:test_download_tubes, manifest_type: 'tube_library_with_tag_sequences', columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid library tube with tag sequences sample manifest with duplicated tags' do
      broadcast_events_count = BroadcastEvent.count
      download = build(:test_download_tubes, manifest_type: 'tube_library_with_tag_sequences', columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid multiplexed library tube with tag sequences sample manifest' do
      broadcast_events_count = BroadcastEvent.count
      download = build(:test_download_tubes, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid multiplexed library tube with tag groups and indexes sample manifest' do
      broadcast_events_count = BroadcastEvent.count
      download = build(:test_download_tubes, manifest_type: 'tube_multiplexed_library', columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will upload a valid plate sample manifest' do
      broadcast_events_count = BroadcastEvent.count
      download = build(:test_download_plates, manifest_type: 'plate_full', columns: SampleManifestExcel.configuration.columns.plate_full.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
      expect(BroadcastEvent.count).to eq broadcast_events_count + 1
      expect(uploader.upload.sample_manifest).to be_completed
    end

    it 'will not upload an invalid 1d tube sample manifest' do
      download = build(:test_download_tubes, manifest_type: 'tube_full', columns: SampleManifestExcel.configuration.columns.tube_full.dup, validation_errors: [:sanger_sample_id_invalid])
      download.save(test_file)
      expect(SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)).to_not be_valid
    end

    it 'will not upload an invalid library tube with tag sequences sample manifest' do
      download = build(:test_download_tubes, manifest_type: 'tube_library_with_tag_sequences', columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup, validation_errors: [:insert_size_from])
      download.save(test_file)
      expect(SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)).to_not be_valid
    end

    it 'will not upload an invalid multiplexed library tube with tag sequences sample manifest' do
      download = build(:test_download_tubes, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup, validation_errors: [:insert_size_from])
      download.save(test_file)
      expect(SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)).to_not be_valid
    end

    it 'will not upload an invalid multiplexed library tube with tag groups and indexes sample manifest' do
      download = build(:test_download_tubes, manifest_type: 'tube_multiplexed_library', columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup, validation_errors: [:insert_size_from])
      download.save(test_file)
      expect(SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)).to_not be_valid
    end

    it 'will not upload an invalid plate sample manifest' do
      download = build(:test_download_plates, manifest_type: 'plate_full', columns: SampleManifestExcel.configuration.columns.plate_full.dup, validation_errors: [:sanger_sample_id_invalid])
      download.save(test_file)
      expect(SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)).to_not be_valid
    end

    it 'will upload a valid partial 1d tube sample manifest' do
      download = build(:test_download_tubes_partial, manifest_type: 'tube_full', columns: SampleManifestExcel.configuration.columns.tube_full.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    it 'will upload a valid partial library tube sample manifest' do
      download = build(:test_download_tubes_partial, manifest_type: 'tube_library_with_tag_sequences', columns: SampleManifestExcel.configuration.columns.tube_library_with_tag_sequences.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    it 'will upload a valid partial multiplexed library tube with tag sequences sample manifest' do
      download = build(:test_download_tubes_partial, manifest_type: 'tube_multiplexed_library_with_tag_sequences', columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library_with_tag_sequences.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    it 'will upload a valid partial multiplexed library tube with tag groups and indexes' do
      download = build(:test_download_tubes_partial, manifest_type: 'tube_multiplexed_library', columns: SampleManifestExcel.configuration.columns.tube_multiplexed_library.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    it 'will upload a valid partial plate sample manifest' do
      download = build(:test_download_plates_partial, columns: SampleManifestExcel.configuration.columns.plate_full.dup)
      download.save(test_file)
      Delayed::Worker.delay_jobs = false
      uploader = SampleManifest::Uploader.new(test_file, SampleManifestExcel.configuration, user, false)
      uploader.run!
      expect(uploader).to be_processed
    end

    after(:each) do
      Delayed::Worker.delay_jobs = true
    end
  end

  after(:each) do
    File.delete(test_file) if File.exist?(test_file)
  end

  after(:all) do
    SampleManifestExcel.reset!
  end
end
