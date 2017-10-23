require 'rails_helper'

describe WorkOrders::Configuration, type: :model, work_order: true do
  let(:configuration) { described_class.new }

  it 'should be comparable' do
    expect(described_class.new).to eq(configuration)
  end

  it 'should be able to add a new file' do
    configuration.add_file 'a_new_file'
    expect(described_class::FILES.length + 1).to eq(configuration.files.length)
    expect(configuration.files).to include(:a_new_file)
    expect(configuration).to respond_to('a_new_file=')
  end

  context 'without a folder' do
    it 'should not be loaded' do
      configuration.load!
      expect(configuration).to_not be_loaded
    end
  end

  context 'with a valid folder' do
    let(:folder)  { File.join('spec', 'data', 'work_orders') }

    before(:each) do
      configuration.folder = folder
      configuration.load!
    end

    it 'should be loaded' do
      expect(configuration).to be_loaded
    end

    it 'should load the work_orders' do
      expect(configuration.work_order_types).to eq(WorkOrders::WorkOrderTypesList.new(configuration.load_file(folder, 'work_order_types')))
    end

    it 'should freeze all of the configuration options' do
      expect(configuration.work_order_types).to be_frozen
    end
  end
end
