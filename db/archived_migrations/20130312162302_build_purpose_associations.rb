#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class BuildPurposeAssociations < ActiveRecord::Migration
  def self.up
    IlluminaHtp::PlatePurposes::BRANCHES.each do |branch|
      IlluminaHtp::PlatePurposes.create_branch(branch)
    end
  end

  def self.down
    IlluminaHtp::PlatePurposes::BRANCHES.each do |branch|
      #
    end
  end

end