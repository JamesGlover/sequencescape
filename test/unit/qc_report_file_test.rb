#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"
require 'timecop'

class QcReport::FileTest < ActiveSupport::TestCase
  context "QcReport File" do

    context 'given a non-csv file' do
      setup do
        @file = File.open("#{RAILS_ROOT}/test/data/190_tube_sample_info.xls")
        @qcr_file = QcReport::File.new(@file,false,'190_tube_sample_info.xls','application/excel')
      end

      should 'fail processing' do
        assert_equal false, @qcr_file.process, "Non-csv file processed unexpectedly"
        assert_equal ["190_tube_sample_info.xls was not a csv file"], @qcr_file.errors
      end

      teardown do
        @file.close unless @file.nil?
      end
    end

    context 'given a non-compatible csv file' do
      setup do
        @file = File.open("#{RAILS_ROOT}/test/data/fluidigm.csv")
        @qcr_file = QcReport::File.new(@file,false,'fluidigm.csv','text/csv')
      end

      should 'fail processing' do
        assert_equal false, @qcr_file.process, "Non-compatible file processed unexpectedly"
        assert_equal ["fluidigm.csv does not appear to be a qc report file. Make sure the Sequencescape QC Report line has not been removed."], @qcr_file.errors
      end

      teardown do
        @file.close unless @file.nil?
      end
    end

    context 'given a file with no report' do
      setup do
        @file = File.open("#{RAILS_ROOT}/test/data/qc_report.csv")
        @qcr_file = QcReport::File.new(@file,false)
      end

      should 'fail processing' do
        assert_equal false, @qcr_file.process, "File with no report processed unexpectedly"
        assert_equal ["Couldn't find the report wtccc_demo_product_20150101000000. Check that the report identifier has not been modified."], @qcr_file.errors
      end

      teardown do
        @file.close unless @file.nil?
      end
    end

    context 'given a file with a report' do
      setup do
        @product = Factory :product, :name => 'Demo Product'
        @criteria = Factory :product_criteria, :product => @product, :version => 1
        @study  = Factory :study, :name => 'Example study'
        Timecop.freeze(DateTime.parse('01/01/2015')) do
          @report = Factory :qc_report, {
            :study => @study,
            :exclude_existing => false,
            :product_criteria => @criteria,
            :state => 'awaiting_proceed'
          }
        end
        @asset_ids = []
        2.times do |i|
          Factory :qc_metric, :qc_report => @report, :qc_decision => (i%2)==0, :asset => Factory(:well, :id=>i+1)
        end
        @file = File.open("#{RAILS_ROOT}/test/data/qc_report.csv")

        @qcr_file = QcReport::File.new(@file,false,'qc_report.csv','text/csv')
      end

      should 'pass processing' do
        assert_equal true, @qcr_file.process, "Processing failed unexpectedly"
        assert_equal [], @qcr_file.errors
      end

      should "complete the report and set the proceed flags" do
        @qcr_file.process
        @report.reload
        assert_equal "complete", @report.state
        assert @report.qc_metrics.all? {|met| met.proceed }, "Not all metrics are proceed"
      end

      should "not adjust the qc_decision flag" do
        @qcr_file.process
        assert_equal ['pass','fail'], @report.qc_metrics.find(:all,:order=>'asset_id ASC').map(&:human_qc_decision)
      end

      teardown do
        @file.close unless @file.nil?
      end
    end

    context 'On overiding' do
      setup do
        @product = Factory.build :product, :name => 'Demo Product'
        @criteria = Factory.build :product_criteria, :product => @product, :version => 1
        @study  = Factory.build :study, :name => 'Example study'
        Timecop.freeze(DateTime.parse('01/01/2015')) do
          @report = Factory :qc_report, {
            :study => @study,
            :exclude_existing => false,
            :product_criteria => @criteria,
            :state => 'awaiting_proceed'
          }
        end
        @asset_ids = []
        2.times do |i|
          m = Factory :qc_metric, :qc_report => @report, :qc_decision => (i%2)==0, :asset => Factory(:well, :id=>i+1)
          @asset_ids << m.asset_id
        end
        @file = File.open("#{RAILS_ROOT}/test/data/qc_report.csv")

        @qcr_file = QcReport::File.new(@file,true,'qc_report.csv','text/csv')
      end

      should "adjust the qc_decision flag" do
        @qcr_file.process
        assert_equal ['pass','pass'], @report.qc_metrics.find(:all,:order=>'asset_id ASC').map(&:human_qc_decision)
      end

      teardown do
        @file.close unless @file.nil?
      end
    end

    context 'With missing assets' do
      setup do
        @product = Factory.build :product, :name => 'Demo Product'
        @criteria = Factory.build :product_criteria, :product => @product, :version => 1
        @study  = Factory.build :study, :name => 'Example study'
        Timecop.freeze(DateTime.parse('01/01/2015')) do
          @report = Factory :qc_report, {
            :study => @study,
            :exclude_existing => false,
            :product_criteria => @criteria,
            :state => 'awaiting_proceed'
          }
        end
        @asset_ids = []
        2.times do |i|
          Factory :qc_metric, :qc_report => @report, :qc_decision => (i%2)==0
        end
        @file = File.open("#{RAILS_ROOT}/test/data/qc_report.csv")

        @qcr_file = QcReport::File.new(@file,true,'qc_report.csv','text/csv')
      end

      should "adjust the qc_decision flag" do
        assert_equal false, @qcr_file.process
        assert_equal ['Could not find assets 1 and 2'], @qcr_file.errors
      end

      teardown do
        @file.close unless @file.nil?
      end
    end
  end
end
