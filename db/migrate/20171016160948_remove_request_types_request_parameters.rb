class RemoveRequestTypesRequestParameters < ActiveRecord::Migration[5.1]
  def change
    remove_column :request_types, :request_parameters, :text
  end
end
