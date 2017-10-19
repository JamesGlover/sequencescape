# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

# A work order groups requests together based on submission and asset
# providing a unified interface for external applications.
# It is likely that its behaviour will be extended in future
class WorkOrder < ApplicationRecord
  has_many :requests
  belongs_to :work_order_type, required: true

  # where.not(work_order_id: nil assists the MySQL query optimizer as otherwise is seems
  # to get confused by the large number of null entries in requests.work_order_id
  has_one :example_request, ->() { order(id: :asc).where.not(work_order_id: nil).readonly }, class_name: 'CustomerRequest'

  belongs_to :study
  belongs_to :project
  belongs_to :source_receptacle, class_name: 'Receptacle'

  has_many :samples, ->() { distinct }, through: :source_receptacle, source: 'samples'

  # Caution! Do not remove or insert values, only append them. Changing the index of existing entries will affect existing
  # records.
  enum unit_of_measurement: [ :flowcells, :libraries, :lanes ]

  validates :number, presence: true, numericality: { greater_than: 0 }
  validates :unit_of_measurement, presence: true

  # The options describing the work-order.
  # Expected options vary between work-order types.
  serialize :options, Hash

  def state=(new_state)
    super
    requests.each do |request|
      request.state = new_state
      request.save!
    end
  end

  def at_risk=(risk)
    super
    requests.each do |request|
      request.customer_accepts_responsibility = risk
      request.save!
    end
  end

  def options=(new_options)
    super(new_options)
    requests.each do |request|
      request.request_metadata_attributes = new_options
      request.save!
    end
  end

  def source_receptacle_type=(_type)
    # Do nothing!
    # Our association isn't actually polymorphic, but JSON API resource thinks it is.
    # This allows it to use different templates for wells/tubes etc. But it also
    # means it trys to set the receptacle type here.
  end
end
