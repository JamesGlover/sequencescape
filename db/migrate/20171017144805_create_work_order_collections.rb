class CreateWorkOrderCollections < ActiveRecord::Migration[5.1]
  def change
    create_table :work_order_collections do |t|
      t.string :name

      t.timestamps
    end
    add_index :work_order_collections, :name, unique: true
  end
end
