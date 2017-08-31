# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class Event::ScannedIntoLabEvent < Event
  after_create :set_qc_state_pending, if: :qc_state_tracked_and_unset?
  alias_method :asset, :eventful

  def self.create_for_asset!(asset, location)
    create!(
      eventful: asset,
      message: "Scanned into #{location.name}",
      content: Date.today.to_s,
      family: 'scanned_into_lab'
    )
  end

  def set_qc_state_pending
    asset.qc_pending
  end

  def qc_state_tracked_and_unset?
    return false unless asset.respond_to?(:qc_state)
    asset.qc_state != 'passed' && asset.qc_state == 'failed'
  end
end
