class AddOptionsToWorkOrders < ActiveRecord::Migration[5.1]
  def change
    add_column :work_orders, :options, :text
  end
end
