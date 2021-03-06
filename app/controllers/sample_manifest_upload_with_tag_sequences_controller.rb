class SampleManifestUploadWithTagSequencesController < ApplicationController # rubocop:todo Style/Documentation
  before_action :login_required

  def new
    prepare_manifest_pagination
  end

  def create
    if params[:upload].present?
      @uploader = SampleManifest::Uploader.new(params[:upload], SampleManifestExcel.configuration, current_user,
                                               params[:override])
      if @uploader.valid?
        if @uploader.run!
          flash[:notice] = 'Sample manifest successfully uploaded.'
          redirect_target = (@uploader.study.present? ? sample_manifests_study_path(@uploader.study) : sample_manifests_path)
          redirect_to redirect_target
        else
          flash.now[:error] = 'Your sample manifest couldn\'t be uploaded.'
          prepare_manifest_pagination
          render :new
        end
      else
        flash.now[:error] = 'Your sample manifest couldn\'t be uploaded. See errors below.'
        prepare_manifest_pagination
        render :new
      end
    else
      flash.now[:error] = 'No file attached'
      prepare_manifest_pagination
      render :new
    end
  end

  def prepare_manifest_pagination
    pending_sample_manifests = SampleManifest.pending_manifests.includes(:study, :supplier, :user,
                                                                         :uploaded_document).paginate(page: params[:page])
    completed_sample_manifests = SampleManifest.completed_manifests.includes(:study, :supplier, :user,
                                                                             :uploaded_document).paginate(page: params[:page])
    @display_manifests = pending_sample_manifests | completed_sample_manifests
    @sample_manifests = SampleManifest.paginate(page: params[:page])
  end
end
