#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddCherrypickForFluidigmRequestTypes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      RequestType.create!(shared_options.merge({
        :key => 'pick_to_sta',
        :name => 'Pick to STA',
        :order => 1,
        :request_class_name => 'CherrypickForPulldownRequest'
        })
      ).tap do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by_name!('Working Dilution')
      end
      RequestType.create!(shared_options.merge({
        :key => 'pick_to_sta2',
        :name => 'Pick to STA2',
        :order => 2,
        :request_class_name => 'CherrypickForPulldownRequest'
        })
      ).tap do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by_name!('STA')
      end
      RequestType.create!(shared_options.merge({
        :key => 'pick_to_fluidigm',
        :name => 'Pick to Fluidigm',
        :order => 3,
        :request_class_name => 'CherrypickForFluidigmRequest'
        })
      ).tap do |rt|
        rt.acceptable_plate_purposes << Purpose.find_by_name!('STA2')
      end
    end
  end

  def self.shared_options
    {
        :workflow => Submission::Workflow.find_by_name('Microarray genotyping'),
        :asset_type => 'Well',
        :target_asset_type => 'Well',
        :initial_state => 'pending'
    }
  end

  def self.down
    ActiveRecord::Base.transaction do
      RequestType.find_all_by_key(['pick_to_sta','pick_to_sta2','pick_to_fluidigm']).each(&:destroy)
    end
  end
end
