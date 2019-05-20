class PlateSummariesController < ApplicationController
  before_action :login_required

  def index
    @plates = Plate.source_plates.with_descendants_owned_by(current_user).order('labware.id desc').page(params[:page])
  end

  def show
    @plate = Plate.find_from_any_barcode(params[:id])
    raise ActiveRecord::RecordNotFound if @plate.nil?

    @custom_metadatum_collection = @plate.custom_metadatum_collection || NullCustomMetadatumCollection.new
    @sequencing_batches = @plate.descendant_lanes.include_creation_batches.map(&:creation_batches).flatten.uniq
  end

  def search
    candidate_plate = Plate.find_from_any_barcode(params[:plate_barcode])
    if candidate_plate.nil? || candidate_plate.source_plate.nil?
      redirect_back fallback_location: root_path, flash: { error: "No suitable plates found for barcode #{params[:plate_barcode]}" }
    else
      redirect_to plate_summary_path(candidate_plate.source_plate.human_barcode)
    end
  end
end
