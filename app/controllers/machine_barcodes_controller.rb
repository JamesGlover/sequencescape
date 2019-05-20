# frozen_string_literal: true

# Used in the flexible cherrypick pipeline layout page
class MachineBarcodesController < ApplicationController
  def show
    asset = Labware.find_by_barcode(params[:id])
    summary = asset.present? ? asset.summary_hash : {}
    status = asset.present? ? 200 : 404
    respond_to do |format|
      format.json { render json: summary, status: status }
    end
  end
end
