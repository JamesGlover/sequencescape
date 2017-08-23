class DropExcessLabwareColumns < ActiveRecord::Migration
  def change
    remove_column 'labware', 'value', :string   ,                   limit: 255
    remove_column 'labware', 'qc_state', :string   ,                limit: 20
    remove_column 'labware', 'resource', :boolean
    remove_column 'labware', 'public_name', :string   ,             limit: 255
    remove_column 'labware', 'archive', :boolean
    remove_column 'labware', 'external_release', :boolean
    remove_column 'labware', 'two_dimensional_barcode', :string   , limit: 255
    remove_column 'labware', 'volume', :decimal  ,                                precision: 10, scale: 2
    remove_column 'labware', 'concentration', :decimal  ,                         precision: 18, scale: 8
    remove_column 'labware', 'legacy_sample_id', :integer  ,        limit: 4
    remove_column 'labware', 'legacy_tag_id', :integer  ,           limit: 4
  end
end
