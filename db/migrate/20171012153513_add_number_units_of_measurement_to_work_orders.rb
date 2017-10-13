# Number and quantity reflect the amount of work requested.
# number: The scalar value
# unit_of_measurement: An enum, reflecting the units expected. (eg. Lanes, Gb)
class AddNumberUnitsOfMeasurementToWorkOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :work_orders, :number, :integer
    add_column :work_orders, :unit_of_measurement, :integer
  end
end
