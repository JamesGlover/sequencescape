require 'rails_helper'

describe SampleManifestExcel::Configuration do
  let(:configuration) { SampleManifestExcel::Configuration.new }

  it 'should be comparable' do
    expect(configuration).to eq SampleManifestExcel::Configuration.new
  end

  it 'should be able to add a new file' do
    configuration.add_file 'a_new_file'
    expect(configuration.files.length).to eq SampleManifestExcel::Configuration::FILES.length + 1
    expect(configuration.files).to include :a_new_file
    expect(configuration).to respond_to('a_new_file=')
  end

  it 'should be able to set and get a tag group' do
    expect(configuration.tag_group).to be nil
    configuration.tag_group = 'Main test group'
    expect(configuration.tag_group).to be_an_instance_of(TagGroup)
    expect(configuration.tag_group.name).to eq 'Main test group'
  end

  describe 'without a folder' do
    before(:each) do
      configuration.load!
    end

    it 'should not be loaded' do
      expect(configuration.loaded?).to be_falsey
    end
  end

  describe 'with a valid folder' do
    let(:folder) { File.join('test', 'data', 'sample_manifest_excel') }

    before(:each) do
      configuration.folder = folder
      configuration.load!
    end

    it 'should be loaded' do
      expect(configuration.loaded?).to be_truthy
    end

    it 'should load the columns' do
      columns = SampleManifestExcel::ColumnList.new(configuration.load_file(folder, 'columns'), configuration.conditional_formattings)
      expect(configuration.columns.all).to eq columns
      configuration.manifest_types.each do |k, v|
        expect(configuration.columns.send(k)).to eq columns.extract(v.columns)
        expect(configuration.columns.find(k)).to eq columns.extract(v.columns)
        expect(configuration.columns.find(k.to_sym)).to eq columns.extract(v.columns)
      end
    end

    it 'should load the conditional formattings' do
      expect(configuration.conditional_formattings).to eq SampleManifestExcel::ConditionalFormattingDefaultList.new(configuration.load_file(folder, 'conditional_formattings'))
    end

    it 'load the manifest types' do
      expect(configuration.manifest_types).to eq SampleManifestExcel::ManifestTypeList.new(configuration.load_file(folder, 'manifest_types'))
    end

    it 'load the ranges' do
      expect(configuration.ranges).to eq SampleManifestExcel::RangeList.new(configuration.load_file(folder, 'ranges'))
    end

    it 'should freeze all of the configuration options' do
      expect(configuration.conditional_formattings.frozen?).to be true
      expect(configuration.manifest_types.frozen?).to be true
      expect(configuration.ranges.frozen?).to be true
      expect(configuration.columns.frozen?).to be true
      expect(configuration.columns.all.frozen?).to be true
      configuration.manifest_types.each do |k, _v|
        expect(configuration.columns.send(k).frozen?).to be true
      end
    end
  end
end
