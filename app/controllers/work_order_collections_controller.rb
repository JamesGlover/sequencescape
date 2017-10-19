class WorkOrderCollectionsController < ApplicationController
  before_action :set_work_order_collection, only: [:show, :edit, :update, :destroy]

  # GET /work_order_collections
  def index
    @work_order_collections = WorkOrderCollection.all
  end

  # GET /work_order_collections/1
  def show
  end

  # GET /work_order_collections/new
  def new
    binding.pry
    @work_order_types = WorkOrderType.all.to_json
    @work_order_collection = WorkOrderCollection.new
  end

  # POST /work_order_collections
  def create
    @work_order_collection = WorkOrderCollection.new(work_order_collection_params)

    if @work_order_collection.save
      redirect_to @work_order_collection, notice: 'Work order collection was successfully created.'
    else
      render :new
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_work_order_collection
      @work_order_collection = WorkOrderCollection.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def work_order_collection_params
      params.require(:work_order_collection).permit(:name)
    end
end
