#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015,2016 Genome Research Ltd.

class BroadcastEvent::Reception < BroadcastEvent

  set_event_type 'scanned_into_lab'
  seed_class Event::ScannedIntoLabEvent

  # Triggered whenever a plate is scanned into a new location

  has_subject(:labware) {|e,be| e.asset }

  has_subjects(:study) {|e,be| e.asset.studies }
  has_subjects(:project) {|e,be| e.asset.projects }

  has_subjects(:stock_plate) {|e,be| e.asset.original_stock_plates }
  has_subjects(:sample) { |e,be| e.asset.contained_samples }

  has_metadata(:location) {|e,be| e.location||e.read_location }

end
