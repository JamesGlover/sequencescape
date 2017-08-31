module SingleReceptacle
  extend ActiveSupport::Concern
  included do
    # Tubes only have one receptacle! You probably don't want to use this method too often
    # but legacy code will probably need it.
    has_one :receptacle, ->() { where(map_id: 1) }, required: true, foreign_key: :labware_id
    has_one :primary_aliquot, through: :receptacle

    set_defaults receptacle: ->(labware) { labware.build_receptacle(map: Map.first) }

    # Fix to ensure that most code 'just works'
    delegate :aliquots, to: :receptacle

    # This section should be in a separate module
    delegate :qc_state, :qc_state=, to: :receptacle

    QC_STATES = [
      ['passed',  'pass'],
      ['failed',  'fail'],
      ['pending', 'pending'],
      [nil, '']
    ]

    QC_STATES.reject { |k, _v| k.nil? }.each do |state, qc_state|
      line = __LINE__ + 1
      class_eval("
        def qc_#{qc_state}
          self.qc_state = #{state.inspect}
          self.save!
        end
      ", __FILE__, line)
    end

    def compatible_qc_state
      QC_STATES.assoc(qc_state).try(:last) || qc_state
    end

    def set_qc_state(state)
      self.qc_state = QC_STATES.rassoc(state).try(:first) || state
      save
      set_external_release(qc_state)
    end

    def has_been_through_qc?
      qc_state.present?
    end

    # resource is a pretty limited flag used to indicate control lanes.
    # It is only used for legacy stuff
    # Again, this belongs elsewhere

    delegate :resource, :resource=, to: :receptacle
  end
end
