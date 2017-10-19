class AddWorkOrderCollectionsIdToWorkOrders < ActiveRecord::Migration[5.1]
  def change
    add_reference :work_orders, :work_order_collection, foreign_key: true
  end
end
