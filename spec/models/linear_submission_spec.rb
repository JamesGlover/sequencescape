# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LinearSubmission do
  MX_ASSET_COUNT = 5
  SX_ASSET_COUNT = 4

  let(:study) { create :study }
  let(:project) { create :project }
  let(:user) { create :user }

  context 'build (Submission factory)' do
    let(:sequencing_request_type) { create :sequencing_request_type }
    let(:purpose) { create :std_mx_tube_purpose }
    let(:request_options) { { 'read_length' => '108', 'fragment_size_required_from' => '150', 'fragment_size_required_to' => '200' } }

    context 'multiplexed submission' do
      context 'Customer decision propagation' do
        let(:library_creation_request_type) { create :well_request_type, target_purpose: purpose, for_multiplexing: true }

        setup do
          @mpx_request_type_ids = [library_creation_request_type.id, sequencing_request_type.id]
          @our_product_criteria = create :product_criteria

          @basic_options = {
            study: study,
            project: project,
            user: user,
            request_types: @mpx_request_type_ids,
            request_options: request_options,
            product: @our_product_criteria.product
          }

          @current_report = create :qc_report, product_criteria: @our_product_criteria
          @stock_well = create :well
          @request_well = create :well
          @request_well.stock_wells.attach!([@stock_well])
          @request_well.reload
          @expected_metric = create :qc_metric, asset: @stock_well, qc_report: @current_report, qc_decision: 'manually_failed', proceed: true

          @mpx_submission = create(:linear_submission, @basic_options.merge(assets: [@request_well])).submission
          @mpx_submission.built!
        end

        it 'set an appropriate criteria and set responsibility' do
          @mpx_submission.process!
          @mpx_submission.requests.each do |request|
            assert request.qc_metrics.include?(@expected_metric), "Metric not included in #{request.request_type.name}: #{request.qc_metrics.inspect}"
            assert_equal true, request.request_metadata.customer_accepts_responsibility, "Customer doesn't accept responsibility"
          end
        end
      end

      context 'basic behaviour' do
        setup do
          @mpx_assets = (1..MX_ASSET_COUNT).map { |i| create(:sample_tube, name: "MX-asset#{i}") }
          @mpx_asset_group = create :asset_group, name: 'MPX', assets: @mpx_assets

          @mpx_request_type = create :multiplexed_library_creation_request_type, target_purpose: purpose
          @mpx_request_type_ids = [@mpx_request_type.id, sequencing_request_type.id]

          @basic_options = {
            study: study,
            project: project,
            user: user,
            assets: @mpx_assets,
            request_types: @mpx_request_type_ids,
            request_options: request_options
          }

          @mpx_submission = create(:linear_submission, @basic_options).submission
          @mpx_submission.built!
        end

        it 'be a multiplexed submission' do
          assert @mpx_submission.multiplexed?
        end

        it "not save a comment if one isn't supplied" do
          assert @mpx_submission.comments.blank?
        end

        context '#process!' do
          context 'single request' do
            setup do
              @comment_count = Comment.count
              @request_count = Request.count
              @mpx_submission.process!
            end

            # Ideally these would be separate asserts, but the setup phase is so slow
            # that we'll wrap them together. If the setup phase can be improved we
            # can split them out again
            it 'create requests but not comments' do
              assert_equal MX_ASSET_COUNT + 1, Request.count - @request_count
              assert_equal @comment_count, Comment.count
            end
          end

          context 'multiple requests after plexing' do
            setup do
              sequencing_request_type_2 = create :sequencing_request_type
              @mpx_request_type_ids = [@mpx_request_type.id, sequencing_request_type_2.id, sequencing_request_type.id]

              @multiple_mpx_submission = create(:linear_submission,
                                                study: study,
                                                project: project,
                                                user: user,
                                                assets: @mpx_assets,
                                                request_types: @mpx_request_type_ids,
                                                request_options: request_options).submission
              @multiple_mpx_submission.built!

              @comment_count = Comment.count
              @request_count = Request.count

              @multiple_mpx_submission.process!
            end

            # Ideally these would be separate its, but the setup phase is so slow
            # that we'll wrap them together. If the setup phase can be improved we
            # can split them out again
            it 'create requests but not comments' do
              assert_equal MX_ASSET_COUNT + 2, Request.count - @request_count
              assert_equal @comment_count, Comment.count
            end
          end
        end
      end
    end

    context 'multi-stage submission' do
      # Multi-stage submissions have two phases of library creation which need to be hooked
      # up correctly.
      let(:library_creation_stage1) { create :library_request_type }
      let(:library_creation_stage2) { create :library_request_type }
      let(:mx_request_type) { create :multiplex_request_type }
      let(:request_type_ids) { [library_creation_stage1.id, library_creation_stage2.id, mx_request_type.id, sequencing_request_type.id] }
      let(:assets) { create_list(:untagged_well, 2) }
      let(:basic_options) do
        {
          study: study,
          project: project,
          user: user,
          request_types: request_type_ids,
          request_options: request_options,
          assets: assets
        }
      end
      let(:submission) do
        create(:linear_submission, basic_options).submission.tap(&:built!)
      end

      it 'builds the submission' do
        submission.process!
        expect(library_creation_stage1.requests.count).to eq(2)
        expect(library_creation_stage2.requests.count).to eq(2)
        expect(sequencing_request_type.requests.count).to eq(1)
      end
    end

    context 'single-plex submission' do
      let(:assets) { (1..SX_ASSET_COUNT).map { |i| create(:sample_tube, name: "Asset#{i}") } }
      let(:library_creation_request_type) { create :library_creation_request_type }
      let(:request_type_ids) { [library_creation_request_type.id, sequencing_request_type.id] }

      setup do
        @submission = create(:linear_submission,
                             study: study,
                             project: project,
                             user: user,
                             assets: assets,
                             request_types: request_type_ids,
                             request_options: request_options,
                             comments: 'This is a comment').submission
        @submission.built!
      end

      it 'not be a multiplexed submission' do
        expect(@submission.multiplexed?).to be false
      end

      it 'save request_types as array of Integers' do
        expect(@submission.orders.first.request_types).to be_a Array
        expect(@submission.orders.first.request_types).to eq(request_type_ids)
      end

      it "save a comment if there's one passed in" do
        assert_equal ['This is a comment'], @submission.comments
      end

      context '#process!' do
        setup do
          @request_count = Request.count
          @submission.process!
        end

        it "change Request.count by #{SX_ASSET_COUNT * 2}" do
          assert_equal SX_ASSET_COUNT * 2, Request.count - @request_count, "Expected Request.count to change by #{SX_ASSET_COUNT * 2}"
        end

        context '#create_requests' do
          setup do
            @request_count =  Request.count
            @comment_count =  Comment.count
            @submission.create_requests
          end

          it "change Request.count by #{SX_ASSET_COUNT * 2}" do
            assert_equal SX_ASSET_COUNT * 2,  Request.count  - @request_count, "Expected Request.count to change by #{SX_ASSET_COUNT * 2}"
          end

          it "change Comment.count by #{SX_ASSET_COUNT * 2}" do
            assert_equal SX_ASSET_COUNT * 2,  Comment.count  - @comment_count, "Expected Comment.count to change by #{SX_ASSET_COUNT * 2}"
          end

          it 'assign submission ids to the requests' do
            assert_equal @submission, @submission.requests.first.submission
          end

          context 'library creation request type' do
            setup do
              @request_to_check = @submission.requests.find_by!(request_type_id: library_creation_request_type.id)
            end

            subject { @request_to_check.request_metadata }

            it 'leaves unspecified values as defaults (nil)' do
              expect(subject.customer_accepts_responsibility).to be nil
              expect(subject.gigabases_expected).to be nil
              expect(subject.library_type).to eq library_creation_request_type.default_library_type.name
            end

            it 'assign fragment_size_required_to and assign fragment_size_required_from' do
              assert_equal '200', subject.fragment_size_required_to
              assert_equal '150', subject.fragment_size_required_from
            end
          end

          context 'sequencing request type' do
            setup do
              @request_to_check = @submission.requests.find_by!(request_type_id: sequencing_request_type.id)
            end

            subject { @request_to_check.request_metadata }

            it 'leaves unspecified values as defaults (nil)' do
              expect(subject.customer_accepts_responsibility).to be nil
              expect(subject.gigabases_expected).to be nil
              expect(subject.library_type).to eq nil
            end

            it 'assign read_length' do
              assert_equal 108, subject.read_length
            end
          end
        end
      end
    end
  end

  context 'process with a multiplier for request type' do
    setup do
      @asset_1 = create(:sample_tube)
      @asset_2 = create(:sample_tube)

      @mx_request_type = create :multiplexed_library_creation_request_type, asset_type: 'SampleTube', target_asset_type: 'LibraryTube', initial_state: 'pending', name: 'Multiplexed Library Creation', order: 1, key: 'multiplexed_library_creation'
      @lib_request_type = create :library_creation_request_type, asset_type: 'SampleTube', target_asset_type: 'LibraryTube', initial_state: 'pending', name: 'Library Creation', order: 1, key: 'library_creation'
      @pe_request_type = create :request_type, asset_type: 'LibraryTube', initial_state: 'pending', name: 'PE sequencing', order: 2, key: 'pe_sequencing'
      @se_request_type = create :request_type, asset_type: 'LibraryTube', initial_state: 'pending', name: 'SE sequencing', order: 2, key: 'se_sequencing'

      @submission_with_multiplication_factor = create(:linear_submission,
                                                      study: study,
                                                      project: project,
                                                      user: user,
                                                      assets: [@asset_1, @asset_2],
                                                      request_types: [@lib_request_type.id, @pe_request_type.id],
                                                      request_options: { :multiplier => { @pe_request_type.id.to_s.to_sym => '5', @lib_request_type.id.to_s.to_sym => '1' }, 'read_length' => '108', 'fragment_size_required_from' => '150', 'fragment_size_required_to' => '200' },
                                                      comments: '').submission
      @submission_with_multiplication_factor.built!
      @mx_submission_with_multiplication_factor = create(:linear_submission,
                                                         study: study,
                                                         project: project,
                                                         user: user,
                                                         assets: [@asset_1, @asset_2],
                                                         request_types: [@mx_request_type.id, @pe_request_type.id],
                                                         request_options: { :multiplier => { @pe_request_type.id.to_s.to_sym => '5', @mx_request_type.id.to_s.to_sym => '1' }, 'read_length' => '108', 'fragment_size_required_from' => '150', 'fragment_size_required_to' => '200' },
                                                         comments: '').submission
      @mx_submission_with_multiplication_factor.built!
    end

    context 'when a multiplication factor of 5 is provided' do
      context 'for non multiplexed libraries and sequencing' do
        setup do
          @request_count = Request.count
          @submission_with_multiplication_factor.process!
        end

        it 'change Request.count by 12' do
          assert_equal 12, Request.count - @request_count, 'Expected Request.count to change by 12'
        end

        it 'create 2 library requests' do
          lib_requests = Request.where(submission_id: @submission_with_multiplication_factor, request_type_id: @lib_request_type.id)
          assert_equal 2, lib_requests.size
        end

        it 'create 10 sequencing requests' do
          seq_requests = Request.where(submission_id: @submission_with_multiplication_factor, request_type_id: @pe_request_type.id)
          assert_equal 10, seq_requests.size
        end
      end

      context 'for non multiplexed libraries and sequencing' do
        setup do
          @mx_submission_with_multiplication_factor.process!
        end
      end
    end
  end
end
