class Event::ScannedIntoLabEvent < Event
  after_create :set_qc_state_pending, if: :qc_state_tracked_and_unset?
  alias_method :asset, :eventful

  def self.create_for_asset!(asset, location_barcode, created_by)
    create!(
      eventful: asset,
      message: "Scanned into #{location_barcode}",
      content: Date.today.to_s,
      family: 'scanned_into_lab',
      created_by: created_by
    )
  end

  def set_qc_state_pending
    asset.qc_pending
  end

  def qc_state_tracked_and_unset?
    return false unless asset.respond_to?(:qc_state)
    asset.qc_state != 'passed' && asset.qc_state == 'failed'
  end
end
