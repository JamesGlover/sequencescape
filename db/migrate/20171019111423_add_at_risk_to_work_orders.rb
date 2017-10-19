class AddAtRiskToWorkOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :work_orders, :at_risk, :boolean
  end
end
