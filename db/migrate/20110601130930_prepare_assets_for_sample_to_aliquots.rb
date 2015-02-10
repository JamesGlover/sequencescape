#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class PrepareAssetsForSampleToAliquots < ActiveRecord::Migration
  def self.up
    add_column :assets, :has_been_visited, :boolean, :default => false
  end

  def self.down
    # Really no point in removing the column because it's a unidirectional migration
  end
end
