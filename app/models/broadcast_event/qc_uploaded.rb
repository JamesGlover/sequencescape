#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015,2016 Genome Research Ltd.

class BroadcastEvent::QcUploaded < BroadcastEvent

  set_event_type 'qc_file_received'
  seed_class QcFile

  # Triggered whenever a plate is scanned into a new location

  has_subject(:labware) {|qc_file,be| qc_file.asset }
  has_subject(:qc_file) {|qc_file,be| qc_file }

  has_subjects(:study) {|qc_file,be| qc_file.asset.studies }
  has_subjects(:project) {|qc_file,be| qc_file.asset.projects }

  has_subjects(:stock_plate) {|qc_file,be| qc_file.asset.original_stock_plates }
  has_subjects(:sample) { |qc_file,be| qc_file.asset.contained_samples }

  has_metadata(:file_type) {|qc_file,be| qc_file.parser.name }

end
