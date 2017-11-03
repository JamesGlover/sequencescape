# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

# A work order type is a simple string identifier of the entire work order
# As initial work orders correspond to single request workflow it will initially
# reflect the request type of the provided request.
class WorkOrderType < ApplicationRecord
  validates :name,
            presence: true,
            # Format constraints are intended mainly to keep things consistent, especially with request type keys.
            format: { with: /\A[a-z0-9_]+\z/, message: 'should only contain lower case letters, numbers and underscores.' },
            uniqueness: true


  delegate :options, :unit_of_measurement, :friendly_name, to: :spec

  def spec
    type_configuration.find(name)
  end

  def options_validator
    spec.options.validator
  end

  def options_hash
    options.hash
  end

  private

  def type_configuration
    WorkOrders.configuration.work_order_types
  end
end
