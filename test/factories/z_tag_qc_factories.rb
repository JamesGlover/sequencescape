#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
Factory.sequence :lot_number do |n|
  "lot#{n}"
end
Factory.sequence :lot_type_name do |n|
  "lot_type#{n}"
end

Factory.define :lot_type do |lot_type|
  lot_type.name           { Factory.next :lot_type_name }
  lot_type.template_class 'PlateTemplate'
  lot_type.target_purpose { Tube::Purpose.stock_library_tube }
end

Factory.define :qcable_creator do |qcable_creator|
  qcable_creator.count    0
  qcable_creator.user    { Factory :user }
  qcable_creator.lot     { Factory :lot }
end

Factory.define :lot do |lot|
  lot.lot_number  { Factory.next :lot_number }
  lot.lot_type    { Factory :lot_type }
  lot.template    { Factory :plate_template_with_well }
  lot.user        { Factory :user }
  lot.received_at '2014-02-01'
end

Factory.define :stamp do |stamp|
  stamp.lot     { Factory :lot }
  stamp.user    { Factory :user }
  stamp.robot   { Factory :robot }
  stamp.tip_lot '555'
end

Factory.define :qcable do |qcable|
  qcable.state  'created'
  qcable.lot    { Factory :lot }
  qcable.qcable_creator { Factory :qcable_creator }
end

Factory.define :plate_template_with_well, :class=>PlateTemplate do |p|
  p.name      "testtemplate2"
  p.value     96
  p.size      96
  p.wells    { [Factory(:well_with_sample_and_without_plate,:map=>Factory(:map))] }
end

Factory.define :qcable_with_asset, :class=>Qcable do |qcable|
  qcable.state  'created'
  qcable.lot    { Factory :lot }
  qcable.qcable_creator { Factory :qcable_creator }
  qcable.asset  {Factory :full_plate }
end
