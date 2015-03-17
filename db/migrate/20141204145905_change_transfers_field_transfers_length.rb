#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class ChangeTransfersFieldTransfersLength < ActiveRecord::Migration
  def self.up
    change_column :transfers, :transfers, :text
  end

  def self.down
    change_column :transfers, :transfers, :string
  end
end