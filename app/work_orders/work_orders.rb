# frozen_string_literal: true

# A WorkOrder represents work requested in Sequencescape
# This module contains tools used to govern:
# - Configuration of different work order types
# - Construction of required lims records (ie. requests for legacy submissions)
module WorkOrders
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  def self.reset!
    @configuration = Configuration.new
  end
end
