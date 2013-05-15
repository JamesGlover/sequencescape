class ::Endpoints::Plates < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:wells,                     :json => 'wells', :to => 'wells', :scoped => 'for_api_plate_json.in_row_major_order')
    has_many(:requests,                  :json => 'requests', :to => 'requests')
    belongs_to(:plate_purpose,           :json => 'plate_purpose')

    has_many(:qc_files,  :json => 'qc_files', :to => 'qc_files', :include=>[]) do
      action(:create) do |qc_file, _|
        ActiveRecord::Base.transaction do
          # request.create!(::Io::Batch.map_parameters_to_attributes(request.json).merge(:user => request.user))
        end
      end
    end

    has_many(:transfers_as_source,       :json => 'source_transfers', :to => 'source_transfers')
    has_many(:transfers_to_tubes,        :json => 'transfers_to_tubes', :to => 'transfers_to_tubes')
    has_many(:transfers_as_destination,   :json => 'creation_transfers', :to => 'creation_transfers')
  end

end
