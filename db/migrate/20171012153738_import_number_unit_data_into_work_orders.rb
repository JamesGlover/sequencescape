class ImportNumberUnitDataIntoWorkOrders < ActiveRecord::Migration[5.1]
  def change
    ActiveRecord::Base.transaction do
      # We don't have many, so lets not do anything fancy
      WorkOrder.includes(:requests).find_each do |work_order|
        count = requests.length
        work_order.update_attributes!(number: count, unit_of_measurement: 'flowcells')
      end
    end
  end
end
