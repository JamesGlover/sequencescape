#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014 Genome Research Ltd.
class AddNewStepToPacbioWorkflow < ActiveRecord::Migration

  class SmrtCellsTask < Task; end

  def self.up
    ActiveRecord::Base.transaction do
      wf = LabInterface::Workflow.find_by_name('PacBio Sample Prep')
      wf.tasks.each do |task|
        task.update_attributes!(:sorted=>task.sorted+1) if task.sorted >= 1
      end
      new_task = PlateTransferTask.create!(
        :name=> 'Transfer to plate',
        :workflow => wf,
        :lab_activity => true,
        :purpose => PlatePurpose.find_by_name('PacBio Sheared'),
        :sorted => 1
      )

    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlateTransferTask.find_by_name('Transfer to plate').destroy
      wf = LabInterface::Workflow.find_by_name('PacBio Sample Prep')
      wf.tasks.each do |task|
        task.update_attributes!(:sorted=>task.sorted-1) if task.sorted >= 3
      end
    end
  end
end
