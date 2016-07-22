#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class Sdb::SampleManifestsController < Sdb::BaseController
  before_filter :set_sample_manifest_id, :only => [:show, :generated]
  before_filter :validate_type,    :only => [:new, :create]

  LIMIT_ERROR_LENGTH = 10000

  # Upload the manifest and store it for later processing
  def upload
    if (params[:sample_manifest].blank?) || (params[:sample_manifest] && params[:sample_manifest][:uploaded].blank? )
      flash[:error] = "No CSV file uploaded"
      return
    end

    @sample_manifest = SampleManifest.find_sample_manifest_from_uploaded_spreadsheet(params[:sample_manifest][:uploaded])
    if @sample_manifest.nil?
      flash[:error] = "Cannot find details about the sample manifest"
      return
    end

    @sample_manifest.update_attributes(params[:sample_manifest])
    @sample_manifest.process(current_user, params[:sample_manifest][:override] == "1")
    flash[:notice] = "Manifest being processed"
  rescue CSV::MalformedCSVError
    flash[:error] = "Invalid CSV file"
  ensure
    redirect_to (@sample_manifest.present? ? sample_manifests_study_path(@sample_manifest.study) : sample_manifests_path)
  end

  def export
    @manifest = SampleManifest.find(params[:id])
    send_data(@manifest.generated_document.current_data,
              :filename => "manifest_#{@manifest.id}.xls",
              :type => 'application/excel')
  end

  def uploaded_spreadsheet
    @manifest = SampleManifest.find(params[:id])
    send_data(@manifest.uploaded_document.current_data,
              :filename => "manifest_#{@manifest.id}.csv",
              :type => 'application/excel')
  end

  def new
    @sample_manifest  = SampleManifest.new(:asset_type => params[:type])
    @study_id         = params[:study_id] || ""
    @studies          = Study.alphabetical
    @suppliers        = Supplier.alphabetical
    @barcode_printers = @sample_manifest.applicable_barcode_printers
    @templates        = SampleManifestExcel.configuration.manifest_types.by_asset_type(params[:type]).to_a
  end

  def printer_options(params)
    barcode_printer_id = params[:sample_manifest][:barcode_printer]
    barcode_printer  = BarcodePrinter.find(barcode_printer_id) unless barcode_printer_id.blank?
    return { :barcode_printer => barcode_printer,
             :only_first_label => (params[:sample_manifest][:only_first_label].to_i == 1) }
  end

  def create

    @sample_manifest_generator = SampleManifestGenerator.new(params[:sample_manifest], 
                                  current_user, SampleManifestExcel.configuration)

    if @sample_manifest_generator.execute 

      printer_options = printer_options(params)
      barcode_printer=printer_options[:barcode_printer]

      unless barcode_printer.nil?
        @sample_manifest_generator.sample_manifest.print_labels(barcode_printer, printer_options)
      end

      redirect_to sample_manifest_path(@sample_manifest_generator.sample_manifest)
    else

      flash[:error] = @sample_manifest_generator.errors.full_messages.join(", ")

      redirect_to new_sample_manifest_path

    end

  end

  # Show the manifest
  def show
    @study_id = @sample_manifest.study_id
    @samples = @sample_manifest.samples.paginate(:page => params[:page])
  end

  def index
    pending_sample_manifests = SampleManifest.pending_manifests.paginate(:page => params[:page])
    completed_sample_manifests = SampleManifest.completed_manifests.paginate(:page => params[:page])
    @display_manifests = pending_sample_manifests | completed_sample_manifests
    @sample_manifests = SampleManifest.paginate(:page => params[:page])
  end

  private
  def set_sample_manifest_id
    @sample_manifest = SampleManifest.find(params[:id])
  end

  def validate_type
    return true if SampleManifest.supported_asset_type?(params[:type])
    flash[:error] = "'#{params[:type]}' is not a supported manifest type."
    begin
      redirect_to :back
    rescue ActionController::RedirectBackError
      redirect_to sample_manifests_path
    end
  end

end
