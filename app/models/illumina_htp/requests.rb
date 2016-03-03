#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013,2014,2015 Genome Research Ltd.
module IlluminaHtp::Requests

  class StdLibraryRequest < Request::LibraryCreation

    fragment_size_details(:no_default, :no_default)

    # Ensure that the bait library information is also included in the pool information.
    def update_pool_information(pool_information)
      super
      pool_information[:target_tube_purpose] = target_tube.purpose.uuid if target_tube
      pool_information[:request_type] = request_type.key
    end

    def role
      order.role
    end

  end

  class SharedLibraryPrep < StdLibraryRequest
    def target_tube
      @target_tube ||= submission.next_requests(self).detect {|r| r.target_tube }.try(:target_tube)
    end

    def on_failed
      submission.next_requests(self).each(&:failed_upstream!)
    end

    validate :valid_purpose?
    def valid_purpose?
      return true if request_type.acceptable_plate_purposes.include?(asset.plate.purpose)
      errors.add(:asset,"#{asset.plate.purpose.name} is not a suitable plate purpose.")
      false
    end

    def failed_downstream!
      change_decision! unless failed?
    end

  end

  class LibraryCompletion < StdLibraryRequest
    module FailUpstream
      def on_failed
        asset.requests_as_target.each(&:failed_downstream!)
      end
    end
    include FailUpstream
  end

  module InitialDownstream
    def outer_request
      asset.requests.detect {|request| request.library_creation? && request.submission_id == self.submission_id }
    end
  end

  class CherrypickedToShear < TransferRequest
    include TransferRequest::InitialTransfer
  end

  class CovarisToSheared < TransferRequest

    redefine_aasm :column => :state do

      state :pending, :initial => true
      state :started
      state :passed
      state :qc_complete
      state :failed
      state :cancelled

      event :start  do transitions :to => :started,     :from => [:pending]                    end
      event :pass   do transitions :to => :passed,      :from => [:pending, :started, :failed] end
      event :qc     do transitions :to => :qc_complete, :from => [:passed]                     end
      event :fail   do transitions :to => :failed,      :from => [:pending, :started, :passed] end
      event :cancel do transitions :to => :cancelled,   :from => [:started, :passed]           end
    end
  end

  class PostShearToAlLibs < TransferRequest

    redefine_aasm :column => :state do

      state :pending, :initial => true
      state :started
      state :fx_transfer
      state :failed,     :enter => :on_failed
      state :passed
      state :cancelled,  :enter => :on_cancelled


      event :start                 do transitions :to => :started, :from => [:pending] end
      event :pass                  do transitions :to => :passed, :from => [:pending,:fx_transfer, :failed] end
      event :fail                  do transitions :to => :failed, :from => [:pending, :started, :passed] end
      event :cancel                do transitions :to => :cancelled, :from => [:started, :passed] end
      event :cancel_before_started do transitions :to => :cancelled, :from => [:pending] end
      event :detach                do transitions :to => :pending, :from => [:pending] end
      event :fx_transfer           do transitions :to => :fx_transfer, :from => [:started] end

    end
  end

  class PrePcrToPcr < TransferRequest
    # This is a legacy state machine.
    redefine_aasm :column => :state do

      state :pending, :initial => true
      state :started_fx
      state :started_mj
      state :passed
      state :failed
      state :cancelled

      event :start_fx do transitions :to => :started_fx,  :from => [:pending]                                    end
      event :start_mj do transitions :to => :started_mj,  :from => [:started_fx]                                 end
      event :pass     do transitions :to => :passed,      :from => [:pending, :started_mj, :failed]              end
      event :fail     do transitions :to => :failed,      :from => [:pending, :started_fx, :started_mj, :passed] end
      event :cancel   do transitions :to => :cancelled,   :from => [:started_fx, :started_mj, :passed]           end
    end
  end

  class PcrXpToPoolPippin < TransferRequest

    redefine_aasm :column => :state do

      state :pending, :initial => true
      state :started
      state :passed
      state :cancelled

      event :start  do transitions :to => :started,     :from => [:pending]                    end
      event :pass   do transitions :to => :passed,      :from => [:pending, :started, :failed] end
      event :cancel do transitions :to => :cancelled,   :from => [:started, :passed, :qc]      end
    end
  end

  class QcCompletableTransfer < TransferRequest

    redefine_aasm :column => :state do

      state :pending, :initial => true
      state :started
      state :passed
      state :qc_complete
      state :failed
      state :cancelled

      event :start  do transitions :to => :started,     :from => [:pending]                    end
      event :pass   do transitions :to => :passed,      :from => [:pending, :started, :failed] end
      event :qc     do transitions :to => :qc_complete, :from => [:passed]                     end
      event :fail   do transitions :to => :failed,      :from => [:pending, :started, :passed] end
      event :cancel do transitions :to => :cancelled,   :from => [:started, :passed, :qc_complete]      end
    end
  end

  # We still subclass here both for backwards compatibility, and to make future state machine changes easier
  class PcrXpToStock < QcCompletableTransfer
  end

  class LibPoolSsToLibPoolSsXp < QcCompletableTransfer
  end

  class LibPoolToLibPoolNorm < QcCompletableTransfer
  end

  class PcrToPcrXp < QcCompletableTransfer
  end

  class PcrXpToLibNorm < QcCompletableTransfer
  end

  class PcrXpToPool < PcrXpToStock
    include InitialDownstream
  end

end
