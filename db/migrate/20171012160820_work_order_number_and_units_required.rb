class WorkOrderNumberAndUnitsRequired < ActiveRecord::Migration[5.1]
  def change
    change_column_null(:work_orders, :number, false)
    change_column_null(:work_orders, :unit_of_measurement, false)
  end
end
