#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddPriorityToSubmission < ActiveRecord::Migration
  def self.up
    add_column :submissions, :priority, :integer, :limit => 1, :null => false, :default => 0
  end

  def self.down
    remove_column :submissions, :priority
  end
end