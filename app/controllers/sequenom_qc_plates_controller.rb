class SequenomQcPlatesController < ApplicationController
  def new
    @barcode_printers  = BarcodePrinterType.find_by_name("384 Well Plate").barcode_printers
    @barcode_printers  = BarcodePrinter.find(:all, :order => "name asc") if @barcode_printers.blank?
    @input_plate_names = input_plate_names()
  end

  def create
    @input_plate_names = input_plate_names()
    @barcode_printers  = BarcodePrinter.all
    barcode_printer    = BarcodePrinter.find(params[:barcode_printer][:id])
    number_of_barcodes = params[:number_of_barcodes].to_i
    input_plate_names   = params[:input_plate_names]
    user_barcode        = params[:user_barcode]

    # It's been decided that a blank dummy plate will be created for each barcode label required
    # Any information stored against the plate's wells should be passed through to the stock plate
    # so should be findable.
    new_plates = []

    # This will hold the first bad plate with errors preventing it's creation
    error  = nil
    begin
      ActiveRecord::Base.transaction do
        new_plates = (1..number_of_barcodes).map do
          PlatePurpose.find_by_name('Sequenom').create!(
            :without_wells,
            :input_plate_names   => input_plate_names,
            :plate_prefix        => params[:plate_prefix],
            :gender_check_bypass => gender_check_bypass,
            :user_barcode        => user_barcode
          )
        end
      end
    rescue ActiveRecord::RecordInvalid => invalid
      error = invalid.to_s
    end

    respond_to do |format|
      if error
        # Something's gone wrong, render the errors on the first plate that failed
        flash[:error] = "Failed to create Sequenom QC Plates: #{error}"
        format.html { render :new }
      else
        # Everything's tickity boo so...
        # print the a label for each plate we created
        new_plates.each { |p| p.print_labels(barcode_printer) }

        # and redirect to a fresh page with an appropriate flash[:notice]
        first_plate    = new_plates.first
        flash[:notice] = "Sequenom #{first_plate.plate_prefix} Plate #{first_plate.name} successfully created and labels printed."

        format.html { redirect_to new_sequenom_qc_plate_path }
      end
    end

  end

  def index
    @sequenom_qc_plates = SequenomQcPlate.paginate(:page => params[:page], :order => "created_at desc")
  end

  private
  # If the current user isn't allowed to bypass the geneder checks don't let them
  # even they're sneaky enough to try and send back the param value anyway!
  def gender_check_bypass
    if current_user.slf_manager? || current_user.manager_or_administrator?
      params[:gender_check_bypass]
    else
      false
    end
  end

  def input_plate_names
    input_plate_names = {}
    (1..4).each { |i| input_plate_names[i] = params[:input_plate_names].try(:[],i.to_s) || "" }
    input_plate_names
  end

end
