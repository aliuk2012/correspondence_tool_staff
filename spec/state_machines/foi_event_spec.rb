require 'rails_helper'

describe 'state machine' do
  def all_user_teams
    @setup.user_teams
  end

  def all_cases
    @setup.cases
  end

  context 'usual suspects' do
    before(:all) do
      DbHousekeeping.clean
      @setup = StandardSetup.new(
        only_cases: [
          :full_awdis_foi,
          :full_awresp_foi,
          :full_awresp_foi_accepted,
          :full_closed_foi,
          :full_draft_foi,
          :full_pdacu_foi_accepted,
          :full_pdacu_foi_unaccepted,
          :full_ppress_foi,
          :full_pprivate_foi,
          :full_responded_foi,
          :full_unassigned_foi,
          :std_awdis_foi,
          :std_awresp_foi,
          :std_closed_foi,
          :std_draft_foi,
          :std_draft_foi_in_escalation_period,
          :std_responded_foi,
          :std_unassigned_foi,
          :trig_awdis_foi,
          :trig_awresp_foi,
          :trig_awresp_foi_accepted,
          :trig_closed_foi,
          :trig_draft_foi,
          :trig_draft_foi_accepted,
          :trig_pdacu_foi,
          :trig_pdacu_foi_accepted,
          :trig_responded_foi,
          :trig_unassigned_foi,
          :trig_unassigned_foi_accepted,
        ]
      )
    end

    after(:all) { DbHousekeeping.clean }

    let(:disclosure_assignment) do
      kase.assignments.approving.for_team(@setup.disclosure_team).first
    end

    let(:press_assignment) do
      kase.assignments.approving.for_team(@setup.press_office_team).first
    end

    let(:private_assignment) do
      kase.assignments.approving.for_team(@setup.private_office_team).first
    end

    describe 'setup' do
      context 'FOI' do
        context 'standard workflow' do
          context 'awaiting dispatch' do
            it 'is in awiting dispatch state with no approver assignments' do
              kase = @setup.std_awdis_foi
              expect(kase.current_state).to eq 'awaiting_dispatch'
              expect(kase.workflow).to eq 'standard'
              expect(kase.approver_assignments).to be_empty
            end
          end
        end

        context 'trigger workflow' do
          context 'awaiting dispatch' do
            let(:kase) { @setup.trig_awdis_foi }
            it 'is trigger workflow' do
              expect(kase.current_state).to eq 'awaiting_dispatch'
              expect(kase.workflow).to eq 'trigger'
              expect(disclosure_assignment.state).to eq 'accepted'
              expect(press_assignment).not_to be_present
              expect(private_assignment).not_to be_present
            end
          end
        end

        context 'full_approval workflow' do
          context 'pending dacu clearance' do
            context 'accepted by disclosure specialist' do
              let(:kase) { @setup.full_pdacu_foi_accepted }

              it 'accepted by all three approving teams ' do
                expect(kase.current_state).to eq 'pending_dacu_clearance'
                expect(kase.workflow).to eq 'full_approval'
                expect(disclosure_assignment.state).to eq 'accepted'
                expect(press_assignment.state).to eq 'accepted'
                expect(private_assignment.state).to eq 'accepted'
              end
            end

            context 'not accepted yet by dacu disclosure' do
              let(:kase) { @setup.full_pdacu_foi_unaccepted }

              it 'accepted by press and private but not disclosure' do
                expect(kase.current_state).to eq 'pending_dacu_clearance'
                expect(kase.workflow).to eq 'full_approval'
                expect(disclosure_assignment.state).to eq 'pending'
                expect(press_assignment.state).to eq 'accepted'
                expect(private_assignment.state).to eq 'accepted'
              end
            end
          end

          context 'awaiting dispatch' do
            let(:kase) { @setup.full_awdis_foi }
            it 'is full approval workflow accepted by press, private and disclosure' do
              expect(kase.current_state).to eq 'awaiting_dispatch'
              expect(kase.workflow).to eq 'full_approval'
              expect(disclosure_assignment.state).to eq 'accepted'
              expect(press_assignment.state).to eq 'accepted'
              expect(private_assignment.state).to eq 'accepted'
            end
          end
        end
      end
    end

    describe :accept_approver_assignment do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :trig_unassigned_foi],
                 [:disclosure_specialist, :trig_awresp_foi],
                 [:disclosure_specialist, :trig_draft_foi],
                 [:disclosure_specialist, :trig_pdacu_foi],
                 [:disclosure_specialist, :full_unassigned_foi],
                 [:disclosure_specialist, :full_awresp_foi],
                 [:disclosure_specialist, :full_draft_foi],
                 [:disclosure_specialist, :full_pdacu_foi_unaccepted],

                 [:disclosure_specialist_coworker, :trig_unassigned_foi],
                 [:disclosure_specialist_coworker, :trig_awresp_foi],
                 [:disclosure_specialist_coworker, :trig_draft_foi],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi],
                 [:disclosure_specialist_coworker, :full_unassigned_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi],
                 [:disclosure_specialist_coworker, :full_draft_foi],
                 [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
               )
      }
    end

    describe :accept_responder_assignment do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:responder, :std_awresp_foi],
                 [:responder, :trig_awresp_foi],
                 [:responder, :full_awresp_foi],
                 [:responder, :trig_awresp_foi_accepted],
                 [:responder, :full_awresp_foi_accepted],
                 [:another_responder_in_same_team, :std_awresp_foi],
                 [:another_responder_in_same_team, :trig_awresp_foi],
                 [:another_responder_in_same_team, :full_awresp_foi],
                 [:another_responder_in_same_team, :trig_awresp_foi_accepted],
                 [:another_responder_in_same_team, :full_awresp_foi_accepted]
               )
      }
    end

    describe :add_message_to_case do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_unassigned_foi],
                 [:disclosure_bmt, :std_awresp_foi],
                 [:disclosure_bmt, :std_draft_foi],
                 [:disclosure_bmt, :std_draft_foi_in_escalation_period],
                 [:disclosure_bmt, :std_awdis_foi],
                 [:disclosure_bmt, :std_responded_foi],
                 [:disclosure_bmt, :std_closed_foi],
                 [:disclosure_bmt, :trig_unassigned_foi],
                 [:disclosure_bmt, :trig_awresp_foi],
                 [:disclosure_bmt, :trig_draft_foi],
                 [:disclosure_bmt, :trig_pdacu_foi],
                 [:disclosure_bmt, :trig_awdis_foi],
                 [:disclosure_bmt, :trig_responded_foi],
                 [:disclosure_bmt, :trig_closed_foi],
                 [:disclosure_bmt, :full_unassigned_foi],
                 [:disclosure_bmt, :full_awresp_foi],
                 [:disclosure_bmt, :full_draft_foi],
                 [:disclosure_bmt, :full_ppress_foi],
                 [:disclosure_bmt, :full_pprivate_foi],
                 [:disclosure_bmt, :full_awdis_foi],
                 [:disclosure_bmt, :full_responded_foi],
                 [:disclosure_bmt, :trig_unassigned_foi_accepted],
                 [:disclosure_bmt, :trig_awresp_foi_accepted],
                 [:disclosure_bmt, :trig_draft_foi_accepted],
                 [:disclosure_bmt, :trig_pdacu_foi_accepted],
                 [:disclosure_bmt, :full_awresp_foi_accepted],
                 [:disclosure_bmt, :full_pdacu_foi_accepted],
                 [:disclosure_bmt, :full_pdacu_foi_unaccepted],
                 [:disclosure_bmt, :full_closed_foi],

                 [:disclosure_specialist, :std_closed_foi],
                 [:disclosure_specialist, :trig_unassigned_foi],
                 [:disclosure_specialist, :trig_awresp_foi],
                 [:disclosure_specialist, :trig_draft_foi],
                 [:disclosure_specialist, :trig_pdacu_foi],
                 [:disclosure_specialist, :trig_awdis_foi],
                 [:disclosure_specialist, :trig_responded_foi],
                 [:disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist, :trig_awresp_foi_accepted],
                 [:disclosure_specialist, :trig_draft_foi_accepted],
                 [:disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist, :trig_closed_foi],
                 [:disclosure_specialist, :full_awresp_foi_accepted],
                 [:disclosure_specialist, :full_unassigned_foi],
                 [:disclosure_specialist, :full_awresp_foi],
                 [:disclosure_specialist, :full_draft_foi],
                 [:disclosure_specialist, :full_ppress_foi],
                 [:disclosure_specialist, :full_pprivate_foi],
                 [:disclosure_specialist, :full_awdis_foi],
                 [:disclosure_specialist, :full_responded_foi],
                 [:disclosure_specialist, :full_pdacu_foi_accepted],
                 [:disclosure_specialist, :full_pdacu_foi_unaccepted],
                 [:disclosure_specialist, :full_closed_foi],

                 [:disclosure_specialist_coworker, :std_closed_foi],
                 [:disclosure_specialist_coworker, :trig_unassigned_foi],
                 [:disclosure_specialist_coworker, :trig_awresp_foi],
                 [:disclosure_specialist_coworker, :trig_draft_foi],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi],
                 [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_closed_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :full_unassigned_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi],
                 [:disclosure_specialist_coworker, :full_draft_foi],
                 [:disclosure_specialist_coworker, :full_ppress_foi],
                 [:disclosure_specialist_coworker, :full_pprivate_foi],
                 [:disclosure_specialist_coworker, :full_responded_foi],
                 [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
                 [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
                 [:disclosure_specialist_coworker, :full_closed_foi],

                 [:another_disclosure_specialist, :std_closed_foi],
                 [:another_disclosure_specialist, :trig_awresp_foi],
                 [:another_disclosure_specialist, :trig_draft_foi],
                 [:another_disclosure_specialist, :trig_pdacu_foi],
                 [:another_disclosure_specialist, :trig_closed_foi],
                 [:another_disclosure_specialist, :trig_awresp_foi_accepted],
                 [:another_disclosure_specialist, :trig_draft_foi_accepted],
                 [:another_disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:another_disclosure_specialist, :full_closed_foi],

                 [:responder, :std_awresp_foi],
                 [:responder, :std_draft_foi],
                 [:responder, :std_draft_foi_in_escalation_period],
                 [:responder, :std_awdis_foi],
                 [:responder, :std_responded_foi],
                 [:responder, :std_closed_foi],
                 [:responder, :trig_awresp_foi],
                 [:responder, :trig_draft_foi],
                 [:responder, :trig_pdacu_foi],
                 [:responder, :trig_awdis_foi],
                 [:responder, :trig_responded_foi],
                 [:responder, :trig_awresp_foi_accepted],
                 [:responder, :trig_draft_foi_accepted],
                 [:responder, :trig_pdacu_foi_accepted],
                 [:responder, :trig_closed_foi],
                 [:responder, :full_awresp_foi_accepted],
                 [:responder, :full_awresp_foi],
                 [:responder, :full_draft_foi],
                 [:responder, :full_ppress_foi],
                 [:responder, :full_pprivate_foi],
                 [:responder, :full_awdis_foi],
                 [:responder, :full_responded_foi],
                 [:responder, :full_pdacu_foi_accepted],
                 [:responder, :full_pdacu_foi_unaccepted],
                 [:responder, :full_closed_foi],

                 [:sar_responder, :std_closed_foi],
                 [:sar_responder, :trig_closed_foi],
                 [:sar_responder, :full_closed_foi],

                 [:another_responder_in_same_team, :std_awresp_foi],
                 [:another_responder_in_same_team, :std_draft_foi],
                 [:another_responder_in_same_team, :std_draft_foi_in_escalation_period],
                 [:another_responder_in_same_team, :std_awdis_foi],
                 [:another_responder_in_same_team, :std_responded_foi],
                 [:another_responder_in_same_team, :std_closed_foi],
                 [:another_responder_in_same_team, :trig_awresp_foi],
                 [:another_responder_in_same_team, :trig_awresp_foi_accepted],
                 [:another_responder_in_same_team, :trig_draft_foi],
                 [:another_responder_in_same_team, :trig_draft_foi_accepted],
                 [:another_responder_in_same_team, :trig_pdacu_foi],
                 [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
                 [:another_responder_in_same_team, :trig_awdis_foi],
                 [:another_responder_in_same_team, :trig_responded_foi],
                 [:another_responder_in_same_team, :trig_closed_foi],
                 [:another_responder_in_same_team, :full_awresp_foi],
                 [:another_responder_in_same_team, :full_awresp_foi_accepted],
                 [:another_responder_in_same_team, :full_draft_foi],
                 [:another_responder_in_same_team, :full_ppress_foi],
                 [:another_responder_in_same_team, :full_pprivate_foi],
                 [:another_responder_in_same_team, :full_awdis_foi],
                 [:another_responder_in_same_team, :full_responded_foi],
                 [:another_responder_in_same_team, :full_pdacu_foi_accepted],
                 [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],
                 [:another_responder_in_same_team, :full_closed_foi],

                 [:another_sar_responder_in_same_team, :std_closed_foi],
                 [:another_sar_responder_in_same_team, :trig_closed_foi],
                 [:another_sar_responder_in_same_team, :full_closed_foi],

                 [:another_responder_in_diff_team, :std_closed_foi],
                 [:another_responder_in_diff_team, :trig_closed_foi],
                 [:another_responder_in_diff_team, :full_closed_foi],

                 [:another_sar_responder_in_diff_team, :std_closed_foi],
                 [:another_sar_responder_in_diff_team, :trig_closed_foi],
                 [:another_sar_responder_in_diff_team, :full_closed_foi],

                 [:press_officer, :std_closed_foi],
                 [:press_officer, :trig_awresp_foi],
                 [:press_officer, :trig_draft_foi],
                 [:press_officer, :trig_pdacu_foi],
                 [:press_officer, :trig_awresp_foi_accepted],
                 [:press_officer, :trig_draft_foi_accepted],
                 [:press_officer, :trig_pdacu_foi_accepted],
                 [:press_officer, :trig_closed_foi],
                 [:press_officer, :full_awresp_foi_accepted],
                 [:press_officer, :full_unassigned_foi],
                 [:press_officer, :full_awresp_foi],
                 [:press_officer, :full_draft_foi],
                 [:press_officer, :full_ppress_foi],
                 [:press_officer, :full_pprivate_foi],
                 [:press_officer, :full_responded_foi],
                 [:press_officer, :full_pdacu_foi_accepted],
                 [:press_officer, :full_pdacu_foi_unaccepted],
                 [:press_officer, :full_awdis_foi],
                 [:press_officer, :full_closed_foi],

                 [:private_officer, :std_closed_foi],
                 [:private_officer, :trig_awresp_foi],
                 [:private_officer, :trig_draft_foi],
                 [:private_officer, :trig_pdacu_foi],
                 [:private_officer, :trig_awresp_foi_accepted],
                 [:private_officer, :trig_draft_foi_accepted],
                 [:private_officer, :trig_pdacu_foi_accepted],
                 [:private_officer, :trig_closed_foi],
                 [:private_officer, :full_awresp_foi_accepted],
                 [:private_officer, :full_unassigned_foi],
                 [:private_officer, :full_awresp_foi],
                 [:private_officer, :full_draft_foi],
                 [:private_officer, :full_ppress_foi],
                 [:private_officer, :full_pprivate_foi],
                 [:private_officer, :full_responded_foi],
                 [:private_officer, :full_pdacu_foi_accepted],
                 [:private_officer, :full_pdacu_foi_unaccepted],
                 [:private_officer, :full_awdis_foi],
                 [:private_officer, :trig_closed_foi],
                 [:private_officer, :full_closed_foi],
               )
      }
    end

    describe :add_responses do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :full_awdis_foi],

                 [:responder, :std_draft_foi],
                 [:responder, :std_awdis_foi],
                 [:responder, :trig_draft_foi],
                 [:responder, :trig_draft_foi_accepted],
                 [:responder, :trig_awdis_foi],
                 [:responder, :full_draft_foi],
                 [:responder, :full_awdis_foi],

                 [:another_responder_in_same_team, :std_draft_foi],
                 [:another_responder_in_same_team, :std_awdis_foi],
                 [:another_responder_in_same_team, :trig_draft_foi],
                 [:another_responder_in_same_team, :trig_draft_foi_accepted],
                 [:another_responder_in_same_team, :trig_awdis_foi],
                 [:another_responder_in_same_team, :full_draft_foi],
                 [:another_responder_in_same_team, :full_awdis_foi],
               )}
    end

    describe :approve do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist, :full_pdacu_foi_accepted],
                 [:press_officer,         :full_ppress_foi],
                 [:private_officer,       :full_pprivate_foi],
               )}
    end

    describe :approve_and_bypass do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :full_pdacu_foi_accepted],
               )}
    end

    describe :assign_responder do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_unassigned_foi],
                 [:disclosure_bmt, :trig_unassigned_foi_accepted],
                 [:disclosure_bmt, :trig_unassigned_foi],
                 [:disclosure_bmt, :full_unassigned_foi],
               )}
    end

    describe :assign_to_new_team do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_awresp_foi],
                 [:disclosure_bmt, :std_draft_foi],
                 [:disclosure_bmt, :std_draft_foi_in_escalation_period],
                 [:disclosure_bmt, :std_closed_foi],
                 [:disclosure_bmt, :trig_awresp_foi],
                 [:disclosure_bmt, :trig_awresp_foi_accepted],
                 [:disclosure_bmt, :trig_draft_foi],
                 [:disclosure_bmt, :trig_draft_foi_accepted],
                 [:disclosure_bmt, :trig_closed_foi],
                 [:disclosure_bmt, :full_awresp_foi],
                 [:disclosure_bmt, :full_awresp_foi_accepted],
                 [:disclosure_bmt, :full_draft_foi],
                 [:disclosure_bmt, :full_closed_foi],
               )}
    end

    describe :close do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_responded_foi],
                 [:disclosure_bmt, :trig_responded_foi],
                 [:disclosure_bmt, :full_responded_foi],
               )}
    end

    describe :destroy_case do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_unassigned_foi],
                 [:disclosure_bmt, :std_awresp_foi],
                 [:disclosure_bmt, :std_draft_foi],
                 [:disclosure_bmt, :std_draft_foi_in_escalation_period],
                 [:disclosure_bmt, :std_awdis_foi],
                 [:disclosure_bmt, :std_responded_foi],
                 [:disclosure_bmt, :std_closed_foi],
                 [:disclosure_bmt, :trig_unassigned_foi],
                 [:disclosure_bmt, :trig_unassigned_foi_accepted],
                 [:disclosure_bmt, :trig_awresp_foi],
                 [:disclosure_bmt, :trig_awresp_foi_accepted],
                 [:disclosure_bmt, :trig_draft_foi],
                 [:disclosure_bmt, :trig_draft_foi_accepted],
                 [:disclosure_bmt, :trig_pdacu_foi],
                 [:disclosure_bmt, :trig_pdacu_foi_accepted],
                 [:disclosure_bmt, :trig_awdis_foi],
                 [:disclosure_bmt, :trig_responded_foi],
                 [:disclosure_bmt, :trig_closed_foi],
                 [:disclosure_bmt, :full_unassigned_foi],
                 [:disclosure_bmt, :full_awresp_foi],
                 [:disclosure_bmt, :full_awresp_foi_accepted],
                 [:disclosure_bmt, :full_draft_foi],
                 [:disclosure_bmt, :full_pdacu_foi_accepted],
                 [:disclosure_bmt, :full_pdacu_foi_unaccepted],
                 [:disclosure_bmt, :full_ppress_foi],
                 [:disclosure_bmt, :full_pprivate_foi],
                 [:disclosure_bmt, :full_awdis_foi],
                 [:disclosure_bmt, :full_responded_foi],
                 [:disclosure_bmt, :full_closed_foi]
               )}
    end

    describe :edit_case do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_unassigned_foi],
                 [:disclosure_bmt, :std_awresp_foi],
                 [:disclosure_bmt, :std_draft_foi],
                 [:disclosure_bmt, :std_draft_foi_in_escalation_period],
                 [:disclosure_bmt, :std_awdis_foi],
                 [:disclosure_bmt, :std_responded_foi],
                 [:disclosure_bmt, :std_closed_foi],
                 [:disclosure_bmt, :trig_unassigned_foi],
                 [:disclosure_bmt, :trig_unassigned_foi_accepted],
                 [:disclosure_bmt, :trig_awresp_foi],
                 [:disclosure_bmt, :trig_awresp_foi_accepted],
                 [:disclosure_bmt, :trig_draft_foi],
                 [:disclosure_bmt, :trig_draft_foi_accepted],
                 [:disclosure_bmt, :trig_pdacu_foi],
                 [:disclosure_bmt, :trig_pdacu_foi_accepted],
                 [:disclosure_bmt, :trig_awdis_foi],
                 [:disclosure_bmt, :trig_responded_foi],
                 [:disclosure_bmt, :trig_closed_foi],
                 [:disclosure_bmt, :full_unassigned_foi],
                 [:disclosure_bmt, :full_awresp_foi],
                 [:disclosure_bmt, :full_awresp_foi_accepted],
                 [:disclosure_bmt, :full_draft_foi],
                 [:disclosure_bmt, :full_pdacu_foi_accepted],
                 [:disclosure_bmt, :full_pdacu_foi_unaccepted],
                 [:disclosure_bmt, :full_ppress_foi],
                 [:disclosure_bmt, :full_pprivate_foi],
                 [:disclosure_bmt, :full_awdis_foi],
                 [:disclosure_bmt, :full_responded_foi],
                 [:disclosure_bmt, :full_closed_foi]
               )}
    end

    describe :extend_for_pit do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_draft_foi],
                 [:disclosure_bmt, :std_draft_foi_in_escalation_period],
                 [:disclosure_bmt, :std_awdis_foi],
                 [:disclosure_bmt, :trig_draft_foi_accepted],
                 [:disclosure_bmt, :trig_draft_foi],
                 [:disclosure_bmt, :trig_pdacu_foi_accepted],
                 [:disclosure_bmt, :trig_pdacu_foi],
                 [:disclosure_bmt, :trig_awdis_foi],
                 [:disclosure_bmt, :full_draft_foi],
                 [:disclosure_bmt, :full_pdacu_foi_unaccepted],
                 [:disclosure_bmt, :full_pdacu_foi_accepted],
                 [:disclosure_bmt, :full_ppress_foi],
                 [:disclosure_bmt, :full_pprivate_foi],
                 [:disclosure_bmt, :full_awdis_foi]
               )
      }
    end

    describe :flag_for_clearance do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_unassigned_foi],
                 [:disclosure_bmt, :std_awresp_foi],
                 [:disclosure_bmt, :std_draft_foi],
                 [:disclosure_bmt, :std_draft_foi_in_escalation_period],
                 [:disclosure_bmt, :std_awdis_foi],
                 [:disclosure_bmt, :trig_unassigned_foi],
                 [:disclosure_bmt, :trig_awresp_foi],
                 [:disclosure_bmt, :trig_draft_foi],
                 [:disclosure_bmt, :full_unassigned_foi],
                 [:disclosure_bmt, :full_awresp_foi],
                 [:disclosure_bmt, :full_draft_foi],
                 [:disclosure_bmt, :trig_unassigned_foi_accepted],
                 [:disclosure_bmt, :trig_awresp_foi_accepted],
                 [:disclosure_bmt, :trig_draft_foi_accepted],
                 [:disclosure_bmt, :full_awresp_foi_accepted],

                 [:disclosure_bmt, :trig_awdis_foi],              # old state machine allows it but shouldn't
                 [:disclosure_bmt, :full_awdis_foi],               # old state machine allows it but shouldn't

                 [:disclosure_specialist, :std_unassigned_foi],
                 [:disclosure_specialist, :std_awresp_foi],
                 [:disclosure_specialist, :std_draft_foi],
                 [:disclosure_specialist, :std_draft_foi_in_escalation_period],
                 [:disclosure_specialist, :trig_unassigned_foi],
                 [:disclosure_specialist, :trig_awresp_foi],
                 [:disclosure_specialist, :trig_draft_foi],
                 [:disclosure_specialist, :full_unassigned_foi],
                 [:disclosure_specialist, :full_awresp_foi],
                 [:disclosure_specialist, :full_draft_foi],
                 [:disclosure_specialist, :full_awdis_foi],
                 [:disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist, :trig_awresp_foi_accepted],
                 [:disclosure_specialist, :trig_draft_foi_accepted],
                 [:disclosure_specialist, :full_awresp_foi_accepted],

                 [:disclosure_specialist_coworker, :std_unassigned_foi],
                 [:disclosure_specialist_coworker, :std_awresp_foi],
                 [:disclosure_specialist_coworker, :std_draft_foi],
                 [:disclosure_specialist_coworker, :std_draft_foi_in_escalation_period],
                 [:disclosure_specialist_coworker, :trig_unassigned_foi],
                 [:disclosure_specialist_coworker, :trig_awresp_foi],
                 [:disclosure_specialist_coworker, :trig_draft_foi],
                 [:disclosure_specialist_coworker, :full_unassigned_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi],
                 [:disclosure_specialist_coworker, :full_draft_foi],
                 [:disclosure_specialist_coworker, :full_awdis_foi],
                 [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
                 [:disclosure_specialist_coworker, :full_awresp_foi_accepted],

                 [:another_disclosure_specialist, :std_unassigned_foi],
                 [:another_disclosure_specialist, :std_awresp_foi],
                 [:another_disclosure_specialist, :std_draft_foi],
                 [:another_disclosure_specialist, :std_draft_foi_in_escalation_period],
                 [:another_disclosure_specialist, :trig_unassigned_foi],
                 [:another_disclosure_specialist, :trig_awresp_foi],
                 [:another_disclosure_specialist, :trig_draft_foi],
                 [:another_disclosure_specialist, :full_unassigned_foi],
                 [:another_disclosure_specialist, :full_awresp_foi],
                 [:another_disclosure_specialist, :full_draft_foi],
                 [:another_disclosure_specialist, :full_awdis_foi],
                 [:another_disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:another_disclosure_specialist, :trig_awresp_foi_accepted],
                 [:another_disclosure_specialist, :trig_draft_foi_accepted],
                 [:another_disclosure_specialist, :full_awresp_foi_accepted],

                 [:press_officer, :std_unassigned_foi],
                 [:press_officer, :std_awresp_foi],
                 [:press_officer, :std_draft_foi],
                 [:press_officer, :std_draft_foi_in_escalation_period],
                 [:press_officer, :trig_unassigned_foi],
                 [:press_officer, :trig_awresp_foi],
                 [:press_officer, :trig_draft_foi],
                 [:press_officer, :full_unassigned_foi],
                 [:press_officer, :full_awresp_foi],
                 [:press_officer, :full_draft_foi],
                 [:press_officer, :trig_unassigned_foi_accepted],
                 [:press_officer, :trig_awresp_foi_accepted],
                 [:press_officer, :trig_draft_foi_accepted],
                 [:press_officer, :full_awresp_foi_accepted],
                 [:press_officer, :full_awdis_foi],

                 [:private_officer, :std_unassigned_foi],
                 [:private_officer, :std_awresp_foi],
                 [:private_officer, :std_draft_foi],
                 [:private_officer, :std_draft_foi_in_escalation_period],
                 [:private_officer, :trig_unassigned_foi],
                 [:private_officer, :trig_awresp_foi],
                 [:private_officer, :trig_draft_foi],
                 [:private_officer, :full_unassigned_foi],
                 [:private_officer, :full_awresp_foi],
                 [:private_officer, :full_draft_foi],
                 [:private_officer, :trig_unassigned_foi_accepted],
                 [:private_officer, :trig_awresp_foi_accepted],
                 [:private_officer, :trig_draft_foi_accepted],
                 [:private_officer, :full_awresp_foi_accepted],
                 [:private_officer, :full_awdis_foi],
               )}
    end

    describe :link_a_case do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_unassigned_foi],
                 [:disclosure_bmt, :std_awresp_foi],
                 [:disclosure_bmt, :std_draft_foi],
                 [:disclosure_bmt, :std_draft_foi_in_escalation_period],
                 [:disclosure_bmt, :std_awdis_foi],
                 [:disclosure_bmt, :std_responded_foi],
                 [:disclosure_bmt, :trig_unassigned_foi],
                 [:disclosure_bmt, :trig_awresp_foi],
                 [:disclosure_bmt, :trig_draft_foi],
                 [:disclosure_bmt, :trig_pdacu_foi],
                 [:disclosure_bmt, :trig_awdis_foi],
                 [:disclosure_bmt, :trig_responded_foi],
                 [:disclosure_bmt, :full_unassigned_foi],
                 [:disclosure_bmt, :full_awresp_foi],
                 [:disclosure_bmt, :full_draft_foi],
                 [:disclosure_bmt, :full_ppress_foi],
                 [:disclosure_bmt, :full_pprivate_foi],
                 [:disclosure_bmt, :full_awdis_foi],
                 [:disclosure_bmt, :full_responded_foi],
                 [:disclosure_bmt, :trig_unassigned_foi_accepted],
                 [:disclosure_bmt, :trig_awresp_foi_accepted],
                 [:disclosure_bmt, :trig_draft_foi_accepted],
                 [:disclosure_bmt, :trig_pdacu_foi_accepted],
                 [:disclosure_bmt, :full_awresp_foi_accepted],
                 [:disclosure_bmt, :full_pdacu_foi_accepted],
                 [:disclosure_bmt, :full_pdacu_foi_unaccepted],
                 [:disclosure_bmt, :std_closed_foi],
                 [:disclosure_bmt, :trig_closed_foi],
                 [:disclosure_bmt, :full_closed_foi],

                 [:disclosure_specialist, :std_unassigned_foi],
                 [:disclosure_specialist, :std_awresp_foi],
                 [:disclosure_specialist, :std_draft_foi],
                 [:disclosure_specialist, :std_draft_foi_in_escalation_period],
                 [:disclosure_specialist, :std_awdis_foi],
                 [:disclosure_specialist, :std_responded_foi],
                 [:disclosure_specialist, :std_closed_foi],
                 [:disclosure_specialist, :trig_unassigned_foi],
                 [:disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist, :trig_awresp_foi],
                 [:disclosure_specialist, :trig_awresp_foi_accepted],
                 [:disclosure_specialist, :trig_draft_foi],
                 [:disclosure_specialist, :trig_draft_foi_accepted],
                 [:disclosure_specialist, :trig_pdacu_foi],
                 [:disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist, :trig_awdis_foi],
                 [:disclosure_specialist, :trig_responded_foi],
                 [:disclosure_specialist, :trig_closed_foi],
                 [:disclosure_specialist, :full_unassigned_foi],
                 [:disclosure_specialist, :full_awresp_foi],
                 [:disclosure_specialist, :full_awresp_foi_accepted],
                 [:disclosure_specialist, :full_draft_foi],
                 [:disclosure_specialist, :full_pdacu_foi_accepted],
                 [:disclosure_specialist, :full_pdacu_foi_unaccepted],
                 [:disclosure_specialist, :full_ppress_foi],
                 [:disclosure_specialist, :full_pprivate_foi],
                 [:disclosure_specialist, :full_awdis_foi],
                 [:disclosure_specialist, :full_responded_foi],
                 [:disclosure_specialist, :full_closed_foi],

                 [:disclosure_specialist_coworker, :std_unassigned_foi],
                 [:disclosure_specialist_coworker, :std_awresp_foi],
                 [:disclosure_specialist_coworker, :std_draft_foi],
                 [:disclosure_specialist_coworker, :std_draft_foi_in_escalation_period],
                 [:disclosure_specialist_coworker, :std_awdis_foi],
                 [:disclosure_specialist_coworker, :std_responded_foi],
                 [:disclosure_specialist_coworker, :std_closed_foi],
                 [:disclosure_specialist_coworker, :trig_unassigned_foi],
                 [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_awresp_foi],
                 [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_draft_foi],
                 [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_awdis_foi],
                 [:disclosure_specialist_coworker, :trig_responded_foi],
                 [:disclosure_specialist_coworker, :trig_closed_foi],
                 [:disclosure_specialist_coworker, :full_unassigned_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :full_draft_foi],
                 [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
                 [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
                 [:disclosure_specialist_coworker, :full_ppress_foi],
                 [:disclosure_specialist_coworker, :full_pprivate_foi],
                 [:disclosure_specialist_coworker, :full_awdis_foi],
                 [:disclosure_specialist_coworker, :full_responded_foi],
                 [:disclosure_specialist_coworker, :full_closed_foi],

                 [:another_disclosure_specialist, :std_unassigned_foi],
                 [:another_disclosure_specialist, :std_awresp_foi],
                 [:another_disclosure_specialist, :std_draft_foi],
                 [:another_disclosure_specialist, :std_draft_foi_in_escalation_period],
                 [:another_disclosure_specialist, :std_awdis_foi],
                 [:another_disclosure_specialist, :std_responded_foi],
                 [:another_disclosure_specialist, :std_closed_foi],
                 [:another_disclosure_specialist, :trig_unassigned_foi],
                 [:another_disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:another_disclosure_specialist, :trig_awresp_foi],
                 [:another_disclosure_specialist, :trig_awresp_foi_accepted],
                 [:another_disclosure_specialist, :trig_draft_foi],
                 [:another_disclosure_specialist, :trig_draft_foi_accepted],
                 [:another_disclosure_specialist, :trig_pdacu_foi],
                 [:another_disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:another_disclosure_specialist, :trig_awdis_foi],
                 [:another_disclosure_specialist, :trig_responded_foi],
                 [:another_disclosure_specialist, :trig_closed_foi],
                 [:another_disclosure_specialist, :full_unassigned_foi],
                 [:another_disclosure_specialist, :full_awresp_foi],
                 [:another_disclosure_specialist, :full_awresp_foi_accepted],
                 [:another_disclosure_specialist, :full_draft_foi],
                 [:another_disclosure_specialist, :full_pdacu_foi_accepted],
                 [:another_disclosure_specialist, :full_pdacu_foi_unaccepted],
                 [:another_disclosure_specialist, :full_ppress_foi],
                 [:another_disclosure_specialist, :full_pprivate_foi],
                 [:another_disclosure_specialist, :full_awdis_foi],
                 [:another_disclosure_specialist, :full_responded_foi],
                 [:another_disclosure_specialist, :full_closed_foi],

                 [:responder, :std_unassigned_foi],
                 [:responder, :std_awresp_foi],
                 [:responder, :std_draft_foi],
                 [:responder, :std_draft_foi_in_escalation_period],
                 [:responder, :std_awdis_foi],
                 [:responder, :std_responded_foi],
                 [:responder, :std_closed_foi],
                 [:responder, :trig_unassigned_foi],
                 [:responder, :trig_unassigned_foi_accepted],
                 [:responder, :trig_awresp_foi],
                 [:responder, :trig_awresp_foi_accepted],
                 [:responder, :trig_draft_foi],
                 [:responder, :trig_draft_foi_accepted],
                 [:responder, :trig_pdacu_foi],
                 [:responder, :trig_pdacu_foi_accepted],
                 [:responder, :trig_awdis_foi],
                 [:responder, :trig_responded_foi],
                 [:responder, :trig_closed_foi],
                 [:responder, :full_unassigned_foi],
                 [:responder, :full_awresp_foi],
                 [:responder, :full_awresp_foi_accepted],
                 [:responder, :full_draft_foi],
                 [:responder, :full_pdacu_foi_accepted],
                 [:responder, :full_pdacu_foi_unaccepted],
                 [:responder, :full_ppress_foi],
                 [:responder, :full_pprivate_foi],
                 [:responder, :full_awdis_foi],
                 [:responder, :full_responded_foi],
                 [:responder, :full_closed_foi],

                 [:sar_responder, :std_unassigned_foi],
                 [:sar_responder, :std_awresp_foi],
                 [:sar_responder, :std_draft_foi],
                 [:sar_responder, :std_draft_foi_in_escalation_period],
                 [:sar_responder, :std_awdis_foi],
                 [:sar_responder, :std_responded_foi],
                 [:sar_responder, :std_closed_foi],
                 [:sar_responder, :trig_unassigned_foi],
                 [:sar_responder, :trig_unassigned_foi_accepted],
                 [:sar_responder, :trig_awresp_foi],
                 [:sar_responder, :trig_awresp_foi_accepted],
                 [:sar_responder, :trig_draft_foi],
                 [:sar_responder, :trig_draft_foi_accepted],
                 [:sar_responder, :trig_pdacu_foi],
                 [:sar_responder, :trig_pdacu_foi_accepted],
                 [:sar_responder, :trig_awdis_foi],
                 [:sar_responder, :trig_responded_foi],
                 [:sar_responder, :trig_closed_foi],
                 [:sar_responder, :full_unassigned_foi],
                 [:sar_responder, :full_awresp_foi],
                 [:sar_responder, :full_awresp_foi_accepted],
                 [:sar_responder, :full_draft_foi],
                 [:sar_responder, :full_pdacu_foi_accepted],
                 [:sar_responder, :full_pdacu_foi_unaccepted],
                 [:sar_responder, :full_ppress_foi],
                 [:sar_responder, :full_pprivate_foi],
                 [:sar_responder, :full_awdis_foi],
                 [:sar_responder, :full_responded_foi],
                 [:sar_responder, :full_closed_foi],

                 [:another_responder_in_same_team, :std_unassigned_foi],
                 [:another_responder_in_same_team, :std_awresp_foi],
                 [:another_responder_in_same_team, :std_draft_foi],
                 [:another_responder_in_same_team, :std_draft_foi_in_escalation_period],
                 [:another_responder_in_same_team, :std_awdis_foi],
                 [:another_responder_in_same_team, :std_responded_foi],
                 [:another_responder_in_same_team, :std_closed_foi],
                 [:another_responder_in_same_team, :trig_unassigned_foi],
                 [:another_responder_in_same_team, :trig_unassigned_foi_accepted],
                 [:another_responder_in_same_team, :trig_awresp_foi],
                 [:another_responder_in_same_team, :trig_awresp_foi_accepted],
                 [:another_responder_in_same_team, :trig_draft_foi],
                 [:another_responder_in_same_team, :trig_draft_foi_accepted],
                 [:another_responder_in_same_team, :trig_pdacu_foi],
                 [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
                 [:another_responder_in_same_team, :trig_awdis_foi],
                 [:another_responder_in_same_team, :trig_responded_foi],
                 [:another_responder_in_same_team, :trig_closed_foi],
                 [:another_responder_in_same_team, :full_unassigned_foi],
                 [:another_responder_in_same_team, :full_awresp_foi],
                 [:another_responder_in_same_team, :full_awresp_foi_accepted],
                 [:another_responder_in_same_team, :full_draft_foi],
                 [:another_responder_in_same_team, :full_pdacu_foi_accepted],
                 [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],
                 [:another_responder_in_same_team, :full_ppress_foi],
                 [:another_responder_in_same_team, :full_pprivate_foi],
                 [:another_responder_in_same_team, :full_awdis_foi],
                 [:another_responder_in_same_team, :full_responded_foi],
                 [:another_responder_in_same_team, :full_closed_foi],

                 [:another_sar_responder_in_same_team, :std_unassigned_foi],
                 [:another_sar_responder_in_same_team, :std_awresp_foi],
                 [:another_sar_responder_in_same_team, :std_draft_foi],
                 [:another_sar_responder_in_same_team, :std_draft_foi_in_escalation_period],
                 [:another_sar_responder_in_same_team, :std_awdis_foi],
                 [:another_sar_responder_in_same_team, :std_responded_foi],
                 [:another_sar_responder_in_same_team, :std_closed_foi],
                 [:another_sar_responder_in_same_team, :trig_unassigned_foi],
                 [:another_sar_responder_in_same_team, :trig_unassigned_foi_accepted],
                 [:another_sar_responder_in_same_team, :trig_awresp_foi],
                 [:another_sar_responder_in_same_team, :trig_awresp_foi_accepted],
                 [:another_sar_responder_in_same_team, :trig_draft_foi],
                 [:another_sar_responder_in_same_team, :trig_draft_foi_accepted],
                 [:another_sar_responder_in_same_team, :trig_pdacu_foi],
                 [:another_sar_responder_in_same_team, :trig_pdacu_foi_accepted],
                 [:another_sar_responder_in_same_team, :trig_awdis_foi],
                 [:another_sar_responder_in_same_team, :trig_responded_foi],
                 [:another_sar_responder_in_same_team, :trig_closed_foi],
                 [:another_sar_responder_in_same_team, :full_unassigned_foi],
                 [:another_sar_responder_in_same_team, :full_awresp_foi],
                 [:another_sar_responder_in_same_team, :full_awresp_foi_accepted],
                 [:another_sar_responder_in_same_team, :full_draft_foi],
                 [:another_sar_responder_in_same_team, :full_pdacu_foi_accepted],
                 [:another_sar_responder_in_same_team, :full_pdacu_foi_unaccepted],
                 [:another_sar_responder_in_same_team, :full_ppress_foi],
                 [:another_sar_responder_in_same_team, :full_pprivate_foi],
                 [:another_sar_responder_in_same_team, :full_awdis_foi],
                 [:another_sar_responder_in_same_team, :full_responded_foi],
                 [:another_sar_responder_in_same_team, :full_closed_foi],

                 [:another_responder_in_diff_team, :std_unassigned_foi],
                 [:another_responder_in_diff_team, :std_awresp_foi],
                 [:another_responder_in_diff_team, :std_draft_foi],
                 [:another_responder_in_diff_team, :std_draft_foi_in_escalation_period],
                 [:another_responder_in_diff_team, :std_awdis_foi],
                 [:another_responder_in_diff_team, :std_responded_foi],
                 [:another_responder_in_diff_team, :std_closed_foi],
                 [:another_responder_in_diff_team, :trig_unassigned_foi],
                 [:another_responder_in_diff_team, :trig_unassigned_foi_accepted],
                 [:another_responder_in_diff_team, :trig_awresp_foi],
                 [:another_responder_in_diff_team, :trig_awresp_foi_accepted],
                 [:another_responder_in_diff_team, :trig_draft_foi],
                 [:another_responder_in_diff_team, :trig_draft_foi_accepted],
                 [:another_responder_in_diff_team, :trig_pdacu_foi],
                 [:another_responder_in_diff_team, :trig_pdacu_foi_accepted],
                 [:another_responder_in_diff_team, :trig_awdis_foi],
                 [:another_responder_in_diff_team, :trig_responded_foi],
                 [:another_responder_in_diff_team, :trig_closed_foi],
                 [:another_responder_in_diff_team, :full_unassigned_foi],
                 [:another_responder_in_diff_team, :full_awresp_foi],
                 [:another_responder_in_diff_team, :full_awresp_foi_accepted],
                 [:another_responder_in_diff_team, :full_draft_foi],
                 [:another_responder_in_diff_team, :full_pdacu_foi_accepted],
                 [:another_responder_in_diff_team, :full_pdacu_foi_unaccepted],
                 [:another_responder_in_diff_team, :full_ppress_foi],
                 [:another_responder_in_diff_team, :full_pprivate_foi],
                 [:another_responder_in_diff_team, :full_awdis_foi],
                 [:another_responder_in_diff_team, :full_responded_foi],
                 [:another_responder_in_diff_team, :full_closed_foi],

                 [:another_sar_responder_in_diff_team, :std_unassigned_foi],
                 [:another_sar_responder_in_diff_team, :std_awresp_foi],
                 [:another_sar_responder_in_diff_team, :std_draft_foi],
                 [:another_sar_responder_in_diff_team, :std_draft_foi_in_escalation_period],
                 [:another_sar_responder_in_diff_team, :std_awdis_foi],
                 [:another_sar_responder_in_diff_team, :std_responded_foi],
                 [:another_sar_responder_in_diff_team, :std_closed_foi],
                 [:another_sar_responder_in_diff_team, :trig_unassigned_foi],
                 [:another_sar_responder_in_diff_team, :trig_unassigned_foi_accepted],
                 [:another_sar_responder_in_diff_team, :trig_awresp_foi],
                 [:another_sar_responder_in_diff_team, :trig_awresp_foi_accepted],
                 [:another_sar_responder_in_diff_team, :trig_draft_foi],
                 [:another_sar_responder_in_diff_team, :trig_draft_foi_accepted],
                 [:another_sar_responder_in_diff_team, :trig_pdacu_foi],
                 [:another_sar_responder_in_diff_team, :trig_pdacu_foi_accepted],
                 [:another_sar_responder_in_diff_team, :trig_awdis_foi],
                 [:another_sar_responder_in_diff_team, :trig_responded_foi],
                 [:another_sar_responder_in_diff_team, :trig_closed_foi],
                 [:another_sar_responder_in_diff_team, :full_unassigned_foi],
                 [:another_sar_responder_in_diff_team, :full_awresp_foi],
                 [:another_sar_responder_in_diff_team, :full_awresp_foi_accepted],
                 [:another_sar_responder_in_diff_team, :full_draft_foi],
                 [:another_sar_responder_in_diff_team, :full_pdacu_foi_accepted],
                 [:another_sar_responder_in_diff_team, :full_pdacu_foi_unaccepted],
                 [:another_sar_responder_in_diff_team, :full_ppress_foi],
                 [:another_sar_responder_in_diff_team, :full_pprivate_foi],
                 [:another_sar_responder_in_diff_team, :full_awdis_foi],
                 [:another_sar_responder_in_diff_team, :full_responded_foi],
                 [:another_sar_responder_in_diff_team, :full_closed_foi],

                 [:press_officer, :std_unassigned_foi],
                 [:press_officer, :std_awresp_foi],
                 [:press_officer, :std_draft_foi],
                 [:press_officer, :std_draft_foi_in_escalation_period],
                 [:press_officer, :std_awdis_foi],
                 [:press_officer, :std_responded_foi],
                 [:press_officer, :std_closed_foi],
                 [:press_officer, :trig_unassigned_foi],
                 [:press_officer, :trig_unassigned_foi_accepted],
                 [:press_officer, :trig_awresp_foi],
                 [:press_officer, :trig_awresp_foi_accepted],
                 [:press_officer, :trig_draft_foi],
                 [:press_officer, :trig_draft_foi_accepted],
                 [:press_officer, :trig_pdacu_foi],
                 [:press_officer, :trig_pdacu_foi_accepted],
                 [:press_officer, :trig_awdis_foi],
                 [:press_officer, :trig_responded_foi],
                 [:press_officer, :trig_closed_foi],
                 [:press_officer, :full_unassigned_foi],
                 [:press_officer, :full_awresp_foi],
                 [:press_officer, :full_awresp_foi_accepted],
                 [:press_officer, :full_draft_foi],
                 [:press_officer, :full_pdacu_foi_accepted],
                 [:press_officer, :full_pdacu_foi_unaccepted],
                 [:press_officer, :full_ppress_foi],
                 [:press_officer, :full_pprivate_foi],
                 [:press_officer, :full_awdis_foi],
                 [:press_officer, :full_responded_foi],
                 [:press_officer, :full_closed_foi],

                 [:private_officer, :std_unassigned_foi],
                 [:private_officer, :std_awresp_foi],
                 [:private_officer, :std_draft_foi],
                 [:private_officer, :std_draft_foi_in_escalation_period],
                 [:private_officer, :std_awdis_foi],
                 [:private_officer, :std_responded_foi],
                 [:private_officer, :std_closed_foi],
                 [:private_officer, :trig_unassigned_foi],
                 [:private_officer, :trig_unassigned_foi_accepted],
                 [:private_officer, :trig_awresp_foi],
                 [:private_officer, :trig_awresp_foi_accepted],
                 [:private_officer, :trig_draft_foi],
                 [:private_officer, :trig_draft_foi_accepted],
                 [:private_officer, :trig_pdacu_foi],
                 [:private_officer, :trig_pdacu_foi_accepted],
                 [:private_officer, :trig_awdis_foi],
                 [:private_officer, :trig_responded_foi],
                 [:private_officer, :trig_closed_foi],
                 [:private_officer, :full_unassigned_foi],
                 [:private_officer, :full_awresp_foi],
                 [:private_officer, :full_awresp_foi_accepted],
                 [:private_officer, :full_draft_foi],
                 [:private_officer, :full_pdacu_foi_accepted],
                 [:private_officer, :full_pdacu_foi_unaccepted],
                 [:private_officer, :full_ppress_foi],
                 [:private_officer, :full_pprivate_foi],
                 [:private_officer, :full_awdis_foi],
                 [:private_officer, :full_responded_foi],
                 [:private_officer, :full_closed_foi],
               )
      }
    end

    describe :reassign_user do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist, :trig_awresp_foi],
                 [:disclosure_specialist, :trig_awresp_foi_accepted],
                 [:disclosure_specialist, :trig_draft_foi],
                 [:disclosure_specialist, :trig_draft_foi_accepted],
                 [:disclosure_specialist, :trig_pdacu_foi],
                 [:disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist, :trig_awdis_foi],
                 [:disclosure_specialist, :full_awresp_foi],
                 [:disclosure_specialist, :full_awresp_foi_accepted],
                 [:disclosure_specialist, :full_draft_foi],
                 [:disclosure_specialist, :full_pdacu_foi_accepted],
                 [:disclosure_specialist, :full_pdacu_foi_unaccepted],
                 [:disclosure_specialist, :full_ppress_foi],
                 [:disclosure_specialist, :full_pprivate_foi],
                 [:disclosure_specialist, :full_awdis_foi],


                 [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_awresp_foi],
                 [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_draft_foi],
                 [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_awdis_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :full_draft_foi],
                 [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
                 [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
                 [:disclosure_specialist_coworker, :full_ppress_foi],
                 [:disclosure_specialist_coworker, :full_pprivate_foi],
                 [:disclosure_specialist_coworker, :full_awdis_foi],

                 [:another_disclosure_specialist, :trig_awresp_foi],
                 [:another_disclosure_specialist, :trig_awresp_foi_accepted],
                 [:another_disclosure_specialist, :trig_draft_foi],
                 [:another_disclosure_specialist, :trig_draft_foi_accepted],
                 [:another_disclosure_specialist, :trig_pdacu_foi],
                 [:another_disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:another_disclosure_specialist, :full_awresp_foi],
                 [:another_disclosure_specialist, :full_awresp_foi_accepted],
                 [:another_disclosure_specialist, :full_draft_foi],
                 [:another_disclosure_specialist, :full_pdacu_foi_accepted],
                 [:another_disclosure_specialist, :full_pdacu_foi_unaccepted],

                 [:responder, :std_draft_foi],
                 [:responder, :std_draft_foi_in_escalation_period],
                 [:responder, :std_awdis_foi],
                 [:responder, :trig_draft_foi],
                 [:responder, :trig_draft_foi_accepted],
                 [:responder, :trig_pdacu_foi],
                 [:responder, :trig_pdacu_foi_accepted],
                 [:responder, :trig_awdis_foi],
                 [:responder, :full_draft_foi],
                 [:responder, :full_pdacu_foi_accepted],
                 [:responder, :full_pdacu_foi_unaccepted],
                 [:responder, :full_ppress_foi],
                 [:responder, :full_pprivate_foi],
                 [:responder, :full_awdis_foi],

                 [:another_responder_in_same_team, :std_draft_foi],
                 [:another_responder_in_same_team, :std_draft_foi_in_escalation_period],
                 [:another_responder_in_same_team, :std_awdis_foi],
                 [:another_responder_in_same_team, :trig_draft_foi],
                 [:another_responder_in_same_team, :trig_draft_foi_accepted],
                 [:another_responder_in_same_team, :trig_pdacu_foi],
                 [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
                 [:another_responder_in_same_team, :trig_awdis_foi],
                 [:another_responder_in_same_team, :full_draft_foi],
                 [:another_responder_in_same_team, :full_pdacu_foi_accepted],
                 [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],
                 [:another_responder_in_same_team, :full_ppress_foi],
                 [:another_responder_in_same_team, :full_pprivate_foi],
                 [:another_responder_in_same_team, :full_awdis_foi],

                 [:press_officer, :trig_awresp_foi],
                 [:press_officer, :trig_awresp_foi_accepted],
                 [:press_officer, :trig_draft_foi],
                 [:press_officer, :trig_draft_foi_accepted],
                 [:press_officer, :trig_pdacu_foi],
                 [:press_officer, :trig_pdacu_foi_accepted],
                 [:press_officer, :full_unassigned_foi],
                 [:press_officer, :full_awresp_foi],
                 [:press_officer, :full_awresp_foi_accepted],
                 [:press_officer, :full_draft_foi],
                 [:press_officer, :full_pdacu_foi_accepted],
                 [:press_officer, :full_pdacu_foi_unaccepted],
                 [:press_officer, :full_ppress_foi],
                 [:press_officer, :full_pprivate_foi],
                 [:press_officer, :full_awdis_foi],

                 [:private_officer, :trig_awresp_foi],
                 [:private_officer, :trig_awresp_foi_accepted],
                 [:private_officer, :trig_draft_foi],
                 [:private_officer, :trig_draft_foi_accepted],
                 [:private_officer, :trig_pdacu_foi],
                 [:private_officer, :trig_pdacu_foi_accepted],
                 [:private_officer, :full_unassigned_foi],
                 [:private_officer, :full_awresp_foi],
                 [:private_officer, :full_awresp_foi_accepted],
                 [:private_officer, :full_draft_foi],
                 [:private_officer, :full_pdacu_foi_accepted],
                 [:private_officer, :full_pdacu_foi_unaccepted],
                 [:private_officer, :full_ppress_foi],
                 [:private_officer, :full_pprivate_foi],
                 [:private_officer, :full_awdis_foi],
               )
      }
    end

    describe :reject_responder_assignment do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:responder, :std_awresp_foi],
                 [:responder, :trig_awresp_foi],
                 [:responder, :trig_awresp_foi_accepted],
                 [:responder, :full_awresp_foi],
                 [:responder, :full_awresp_foi_accepted],

                 [:another_responder_in_same_team, :std_awresp_foi],
                 [:another_responder_in_same_team,:trig_awresp_foi_accepted],
                 [:another_responder_in_same_team,:trig_awresp_foi],
                 [:another_responder_in_same_team, :full_awresp_foi],
                 [:another_responder_in_same_team,:full_awresp_foi_accepted],
               )
      }
    end

    describe :remove_linked_case do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_unassigned_foi],
                 [:disclosure_bmt, :std_awresp_foi],
                 [:disclosure_bmt, :std_draft_foi],
                 [:disclosure_bmt, :std_draft_foi_in_escalation_period],
                 [:disclosure_bmt, :std_awdis_foi],
                 [:disclosure_bmt, :std_responded_foi],
                 [:disclosure_bmt, :trig_unassigned_foi],
                 [:disclosure_bmt, :trig_awresp_foi],
                 [:disclosure_bmt, :trig_draft_foi],
                 [:disclosure_bmt, :trig_pdacu_foi],
                 [:disclosure_bmt, :trig_pdacu_foi_accepted],
                 [:disclosure_bmt, :trig_awdis_foi],
                 [:disclosure_bmt, :trig_responded_foi],
                 [:disclosure_bmt, :full_unassigned_foi],
                 [:disclosure_bmt, :full_awresp_foi],
                 [:disclosure_bmt, :full_draft_foi],
                 [:disclosure_bmt, :full_ppress_foi],
                 [:disclosure_bmt, :full_pprivate_foi],
                 [:disclosure_bmt, :full_awdis_foi],
                 [:disclosure_bmt, :full_responded_foi],
                 [:disclosure_bmt, :trig_unassigned_foi_accepted],
                 [:disclosure_bmt, :trig_awresp_foi_accepted],
                 [:disclosure_bmt, :trig_draft_foi_accepted],
                 [:disclosure_bmt, :full_awresp_foi_accepted],
                 [:disclosure_bmt, :full_pdacu_foi_accepted],
                 [:disclosure_bmt, :full_pdacu_foi_unaccepted],
                 [:disclosure_bmt, :std_closed_foi],
                 [:disclosure_bmt, :trig_closed_foi],
                 [:disclosure_bmt, :full_closed_foi],

                 [:disclosure_specialist, :std_unassigned_foi],
                 [:disclosure_specialist, :std_awresp_foi],
                 [:disclosure_specialist, :std_draft_foi],
                 [:disclosure_specialist, :std_draft_foi_in_escalation_period],
                 [:disclosure_specialist, :std_awdis_foi],
                 [:disclosure_specialist, :std_responded_foi],
                 [:disclosure_specialist, :std_closed_foi],
                 [:disclosure_specialist, :trig_unassigned_foi],
                 [:disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist, :trig_awresp_foi],
                 [:disclosure_specialist, :trig_awresp_foi_accepted],
                 [:disclosure_specialist, :trig_draft_foi],
                 [:disclosure_specialist, :trig_draft_foi_accepted],
                 [:disclosure_specialist, :trig_pdacu_foi],
                 [:disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist, :trig_awdis_foi],
                 [:disclosure_specialist, :trig_responded_foi],
                 [:disclosure_specialist, :trig_closed_foi],
                 [:disclosure_specialist, :full_unassigned_foi],
                 [:disclosure_specialist, :full_awresp_foi],
                 [:disclosure_specialist, :full_awresp_foi_accepted],
                 [:disclosure_specialist, :full_draft_foi],
                 [:disclosure_specialist, :full_pdacu_foi_accepted],
                 [:disclosure_specialist, :full_pdacu_foi_unaccepted],
                 [:disclosure_specialist, :full_ppress_foi],
                 [:disclosure_specialist, :full_pprivate_foi],
                 [:disclosure_specialist, :full_awdis_foi],
                 [:disclosure_specialist, :full_responded_foi],
                 [:disclosure_specialist, :full_closed_foi],

                 [:another_disclosure_specialist, :std_unassigned_foi],
                 [:another_disclosure_specialist, :std_awresp_foi],
                 [:another_disclosure_specialist, :std_draft_foi],
                 [:another_disclosure_specialist, :std_draft_foi_in_escalation_period],
                 [:another_disclosure_specialist, :std_awdis_foi],
                 [:another_disclosure_specialist, :std_responded_foi],
                 [:another_disclosure_specialist, :std_closed_foi],
                 [:another_disclosure_specialist, :trig_unassigned_foi],
                 [:another_disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:another_disclosure_specialist, :trig_awresp_foi],
                 [:another_disclosure_specialist, :trig_awresp_foi_accepted],
                 [:another_disclosure_specialist, :trig_draft_foi],
                 [:another_disclosure_specialist, :trig_draft_foi_accepted],
                 [:another_disclosure_specialist, :trig_pdacu_foi],
                 [:another_disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:another_disclosure_specialist, :trig_awdis_foi],
                 [:another_disclosure_specialist, :trig_responded_foi],
                 [:another_disclosure_specialist, :trig_closed_foi],
                 [:another_disclosure_specialist, :full_unassigned_foi],
                 [:another_disclosure_specialist, :full_awresp_foi],
                 [:another_disclosure_specialist, :full_awresp_foi_accepted],
                 [:another_disclosure_specialist, :full_draft_foi],
                 [:another_disclosure_specialist, :full_pdacu_foi_accepted],
                 [:another_disclosure_specialist, :full_pdacu_foi_unaccepted],
                 [:another_disclosure_specialist, :full_ppress_foi],
                 [:another_disclosure_specialist, :full_pprivate_foi],
                 [:another_disclosure_specialist, :full_awdis_foi],
                 [:another_disclosure_specialist, :full_responded_foi],
                 [:another_disclosure_specialist, :full_closed_foi],

                 [:disclosure_specialist_coworker, :std_unassigned_foi],
                 [:disclosure_specialist_coworker, :std_awresp_foi],
                 [:disclosure_specialist_coworker, :std_draft_foi],
                 [:disclosure_specialist_coworker, :std_draft_foi_in_escalation_period],
                 [:disclosure_specialist_coworker, :std_awdis_foi],
                 [:disclosure_specialist_coworker, :std_responded_foi],
                 [:disclosure_specialist_coworker, :std_closed_foi],
                 [:disclosure_specialist_coworker, :trig_unassigned_foi],
                 [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_awresp_foi],
                 [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_draft_foi],
                 [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_awdis_foi],
                 [:disclosure_specialist_coworker, :trig_responded_foi],
                 [:disclosure_specialist_coworker, :trig_closed_foi],
                 [:disclosure_specialist_coworker, :full_unassigned_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi],
                 [:disclosure_specialist_coworker, :full_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :full_draft_foi],
                 [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
                 [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
                 [:disclosure_specialist_coworker, :full_ppress_foi],
                 [:disclosure_specialist_coworker, :full_pprivate_foi],
                 [:disclosure_specialist_coworker, :full_awdis_foi],
                 [:disclosure_specialist_coworker, :full_responded_foi],
                 [:disclosure_specialist_coworker, :full_closed_foi],

                 [:responder, :std_unassigned_foi],
                 [:responder, :std_awresp_foi],
                 [:responder, :std_draft_foi],
                 [:responder, :std_draft_foi_in_escalation_period],
                 [:responder, :std_awdis_foi],
                 [:responder, :std_responded_foi],
                 [:responder, :std_closed_foi],
                 [:responder, :trig_unassigned_foi],
                 [:responder, :trig_unassigned_foi_accepted],
                 [:responder, :trig_awresp_foi],
                 [:responder, :trig_awresp_foi_accepted],
                 [:responder, :trig_draft_foi],
                 [:responder, :trig_draft_foi_accepted],
                 [:responder, :trig_pdacu_foi],
                 [:responder, :trig_pdacu_foi_accepted],
                 [:responder, :trig_awdis_foi],
                 [:responder, :trig_responded_foi],
                 [:responder, :trig_closed_foi],
                 [:responder, :full_unassigned_foi],
                 [:responder, :full_awresp_foi],
                 [:responder, :full_awresp_foi_accepted],
                 [:responder, :full_draft_foi],
                 [:responder, :full_pdacu_foi_accepted],
                 [:responder, :full_pdacu_foi_unaccepted],
                 [:responder, :full_ppress_foi],
                 [:responder, :full_pprivate_foi],
                 [:responder, :full_awdis_foi],
                 [:responder, :full_responded_foi],
                 [:responder, :full_closed_foi],

                 [:sar_responder, :std_unassigned_foi],
                 [:sar_responder, :std_awresp_foi],
                 [:sar_responder, :std_draft_foi],
                 [:sar_responder, :std_draft_foi_in_escalation_period],
                 [:sar_responder, :std_awdis_foi],
                 [:sar_responder, :std_responded_foi],
                 [:sar_responder, :std_closed_foi],
                 [:sar_responder, :trig_unassigned_foi],
                 [:sar_responder, :trig_unassigned_foi_accepted],
                 [:sar_responder, :trig_awresp_foi],
                 [:sar_responder, :trig_awresp_foi_accepted],
                 [:sar_responder, :trig_draft_foi],
                 [:sar_responder, :trig_draft_foi_accepted],
                 [:sar_responder, :trig_pdacu_foi],
                 [:sar_responder, :trig_pdacu_foi_accepted],
                 [:sar_responder, :trig_awdis_foi],
                 [:sar_responder, :trig_responded_foi],
                 [:sar_responder, :trig_closed_foi],
                 [:sar_responder, :full_unassigned_foi],
                 [:sar_responder, :full_awresp_foi],
                 [:sar_responder, :full_awresp_foi_accepted],
                 [:sar_responder, :full_draft_foi],
                 [:sar_responder, :full_pdacu_foi_accepted],
                 [:sar_responder, :full_pdacu_foi_unaccepted],
                 [:sar_responder, :full_ppress_foi],
                 [:sar_responder, :full_pprivate_foi],
                 [:sar_responder, :full_awdis_foi],
                 [:sar_responder, :full_responded_foi],
                 [:sar_responder, :full_closed_foi],

                 [:another_responder_in_same_team, :std_unassigned_foi],
                 [:another_responder_in_same_team, :std_awresp_foi],
                 [:another_responder_in_same_team, :std_draft_foi],
                 [:another_responder_in_same_team, :std_draft_foi_in_escalation_period],
                 [:another_responder_in_same_team, :std_awdis_foi],
                 [:another_responder_in_same_team, :std_responded_foi],
                 [:another_responder_in_same_team, :std_closed_foi],
                 [:another_responder_in_same_team, :trig_unassigned_foi],
                 [:another_responder_in_same_team, :trig_unassigned_foi_accepted],
                 [:another_responder_in_same_team, :trig_awresp_foi],
                 [:another_responder_in_same_team, :trig_awresp_foi_accepted],
                 [:another_responder_in_same_team, :trig_draft_foi],
                 [:another_responder_in_same_team, :trig_draft_foi_accepted],
                 [:another_responder_in_same_team, :trig_pdacu_foi],
                 [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
                 [:another_responder_in_same_team, :trig_awdis_foi],
                 [:another_responder_in_same_team, :trig_responded_foi],
                 [:another_responder_in_same_team, :trig_closed_foi],
                 [:another_responder_in_same_team, :full_unassigned_foi],
                 [:another_responder_in_same_team, :full_awresp_foi],
                 [:another_responder_in_same_team, :full_awresp_foi_accepted],
                 [:another_responder_in_same_team, :full_draft_foi],
                 [:another_responder_in_same_team, :full_pdacu_foi_accepted],
                 [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],
                 [:another_responder_in_same_team, :full_ppress_foi],
                 [:another_responder_in_same_team, :full_pprivate_foi],
                 [:another_responder_in_same_team, :full_awdis_foi],
                 [:another_responder_in_same_team, :full_responded_foi],
                 [:another_responder_in_same_team, :full_closed_foi],

                 [:another_sar_responder_in_same_team, :std_unassigned_foi],
                 [:another_sar_responder_in_same_team, :std_awresp_foi],
                 [:another_sar_responder_in_same_team, :std_draft_foi],
                 [:another_sar_responder_in_same_team, :std_draft_foi_in_escalation_period],
                 [:another_sar_responder_in_same_team, :std_awdis_foi],
                 [:another_sar_responder_in_same_team, :std_responded_foi],
                 [:another_sar_responder_in_same_team, :std_closed_foi],
                 [:another_sar_responder_in_same_team, :trig_unassigned_foi],
                 [:another_sar_responder_in_same_team, :trig_unassigned_foi_accepted],
                 [:another_sar_responder_in_same_team, :trig_awresp_foi],
                 [:another_sar_responder_in_same_team, :trig_awresp_foi_accepted],
                 [:another_sar_responder_in_same_team, :trig_draft_foi],
                 [:another_sar_responder_in_same_team, :trig_draft_foi_accepted],
                 [:another_sar_responder_in_same_team, :trig_pdacu_foi],
                 [:another_sar_responder_in_same_team, :trig_pdacu_foi_accepted],
                 [:another_sar_responder_in_same_team, :trig_awdis_foi],
                 [:another_sar_responder_in_same_team, :trig_responded_foi],
                 [:another_sar_responder_in_same_team, :trig_closed_foi],
                 [:another_sar_responder_in_same_team, :full_unassigned_foi],
                 [:another_sar_responder_in_same_team, :full_awresp_foi],
                 [:another_sar_responder_in_same_team, :full_awresp_foi_accepted],
                 [:another_sar_responder_in_same_team, :full_draft_foi],
                 [:another_sar_responder_in_same_team, :full_pdacu_foi_accepted],
                 [:another_sar_responder_in_same_team, :full_pdacu_foi_unaccepted],
                 [:another_sar_responder_in_same_team, :full_ppress_foi],
                 [:another_sar_responder_in_same_team, :full_pprivate_foi],
                 [:another_sar_responder_in_same_team, :full_awdis_foi],
                 [:another_sar_responder_in_same_team, :full_responded_foi],
                 [:another_sar_responder_in_same_team, :full_closed_foi],

                 [:another_responder_in_diff_team, :std_unassigned_foi],
                 [:another_responder_in_diff_team, :std_awresp_foi],
                 [:another_responder_in_diff_team, :std_draft_foi],
                 [:another_responder_in_diff_team, :std_draft_foi_in_escalation_period],
                 [:another_responder_in_diff_team, :std_awdis_foi],
                 [:another_responder_in_diff_team, :std_responded_foi],
                 [:another_responder_in_diff_team, :std_closed_foi],
                 [:another_responder_in_diff_team, :trig_unassigned_foi],
                 [:another_responder_in_diff_team, :trig_unassigned_foi_accepted],
                 [:another_responder_in_diff_team, :trig_awresp_foi],
                 [:another_responder_in_diff_team, :trig_awresp_foi_accepted],
                 [:another_responder_in_diff_team, :trig_draft_foi],
                 [:another_responder_in_diff_team, :trig_draft_foi_accepted],
                 [:another_responder_in_diff_team, :trig_pdacu_foi],
                 [:another_responder_in_diff_team, :trig_pdacu_foi_accepted],
                 [:another_responder_in_diff_team, :trig_awdis_foi],
                 [:another_responder_in_diff_team, :trig_responded_foi],
                 [:another_responder_in_diff_team, :trig_closed_foi],
                 [:another_responder_in_diff_team, :full_unassigned_foi],
                 [:another_responder_in_diff_team, :full_awresp_foi],
                 [:another_responder_in_diff_team, :full_awresp_foi_accepted],
                 [:another_responder_in_diff_team, :full_draft_foi],
                 [:another_responder_in_diff_team, :full_pdacu_foi_accepted],
                 [:another_responder_in_diff_team, :full_pdacu_foi_unaccepted],
                 [:another_responder_in_diff_team, :full_ppress_foi],
                 [:another_responder_in_diff_team, :full_pprivate_foi],
                 [:another_responder_in_diff_team, :full_awdis_foi],
                 [:another_responder_in_diff_team, :full_responded_foi],
                 [:another_responder_in_diff_team, :full_closed_foi],

                 [:another_sar_responder_in_diff_team, :std_unassigned_foi],
                 [:another_sar_responder_in_diff_team, :std_awresp_foi],
                 [:another_sar_responder_in_diff_team, :std_draft_foi],
                 [:another_sar_responder_in_diff_team, :std_draft_foi_in_escalation_period],
                 [:another_sar_responder_in_diff_team, :std_awdis_foi],
                 [:another_sar_responder_in_diff_team, :std_responded_foi],
                 [:another_sar_responder_in_diff_team, :std_closed_foi],
                 [:another_sar_responder_in_diff_team, :trig_unassigned_foi],
                 [:another_sar_responder_in_diff_team, :trig_unassigned_foi_accepted],
                 [:another_sar_responder_in_diff_team, :trig_awresp_foi],
                 [:another_sar_responder_in_diff_team, :trig_awresp_foi_accepted],
                 [:another_sar_responder_in_diff_team, :trig_draft_foi],
                 [:another_sar_responder_in_diff_team, :trig_draft_foi_accepted],
                 [:another_sar_responder_in_diff_team, :trig_pdacu_foi],
                 [:another_sar_responder_in_diff_team, :trig_pdacu_foi_accepted],
                 [:another_sar_responder_in_diff_team, :trig_awdis_foi],
                 [:another_sar_responder_in_diff_team, :trig_responded_foi],
                 [:another_sar_responder_in_diff_team, :trig_closed_foi],
                 [:another_sar_responder_in_diff_team, :full_unassigned_foi],
                 [:another_sar_responder_in_diff_team, :full_awresp_foi],
                 [:another_sar_responder_in_diff_team, :full_awresp_foi_accepted],
                 [:another_sar_responder_in_diff_team, :full_draft_foi],
                 [:another_sar_responder_in_diff_team, :full_pdacu_foi_accepted],
                 [:another_sar_responder_in_diff_team, :full_pdacu_foi_unaccepted],
                 [:another_sar_responder_in_diff_team, :full_ppress_foi],
                 [:another_sar_responder_in_diff_team, :full_pprivate_foi],
                 [:another_sar_responder_in_diff_team, :full_awdis_foi],
                 [:another_sar_responder_in_diff_team, :full_responded_foi],
                 [:another_sar_responder_in_diff_team, :full_closed_foi],

                 [:press_officer, :std_unassigned_foi],
                 [:press_officer, :std_awresp_foi],
                 [:press_officer, :std_draft_foi],
                 [:press_officer, :std_draft_foi_in_escalation_period],
                 [:press_officer, :std_awdis_foi],
                 [:press_officer, :std_responded_foi],
                 [:press_officer, :std_closed_foi],
                 [:press_officer, :trig_unassigned_foi],
                 [:press_officer, :trig_unassigned_foi_accepted],
                 [:press_officer, :trig_awresp_foi],
                 [:press_officer, :trig_awresp_foi_accepted],
                 [:press_officer, :trig_draft_foi],
                 [:press_officer, :trig_draft_foi_accepted],
                 [:press_officer, :trig_pdacu_foi],
                 [:press_officer, :trig_pdacu_foi_accepted],
                 [:press_officer, :trig_awdis_foi],
                 [:press_officer, :trig_responded_foi],
                 [:press_officer, :trig_closed_foi],
                 [:press_officer, :full_unassigned_foi],
                 [:press_officer, :full_awresp_foi],
                 [:press_officer, :full_awresp_foi_accepted],
                 [:press_officer, :full_draft_foi],
                 [:press_officer, :full_pdacu_foi_accepted],
                 [:press_officer, :full_pdacu_foi_unaccepted],
                 [:press_officer, :full_ppress_foi],
                 [:press_officer, :full_pprivate_foi],
                 [:press_officer, :full_awdis_foi],
                 [:press_officer, :full_responded_foi],
                 [:press_officer, :full_closed_foi],

                 [:private_officer, :std_unassigned_foi],
                 [:private_officer, :std_awresp_foi],
                 [:private_officer, :std_draft_foi],
                 [:private_officer, :std_draft_foi_in_escalation_period],
                 [:private_officer, :std_awdis_foi],
                 [:private_officer, :std_responded_foi],
                 [:private_officer, :std_closed_foi],
                 [:private_officer, :trig_unassigned_foi],
                 [:private_officer, :trig_unassigned_foi_accepted],
                 [:private_officer, :trig_awresp_foi],
                 [:private_officer, :trig_awresp_foi_accepted],
                 [:private_officer, :trig_draft_foi],
                 [:private_officer, :trig_draft_foi_accepted],
                 [:private_officer, :trig_pdacu_foi],
                 [:private_officer, :trig_pdacu_foi_accepted],
                 [:private_officer, :trig_awdis_foi],
                 [:private_officer, :trig_responded_foi],
                 [:private_officer, :trig_closed_foi],
                 [:private_officer, :full_unassigned_foi],
                 [:private_officer, :full_awresp_foi],
                 [:private_officer, :full_awresp_foi_accepted],
                 [:private_officer, :full_draft_foi],
                 [:private_officer, :full_pdacu_foi_accepted],
                 [:private_officer, :full_pdacu_foi_unaccepted],
                 [:private_officer, :full_ppress_foi],
                 [:private_officer, :full_pprivate_foi],
                 [:private_officer, :full_awdis_foi],
                 [:private_officer, :full_responded_foi],
                 [:private_officer, :full_closed_foi],
               )
      }
    end

    describe :remove_response do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:responder, :std_awdis_foi],
                 [:responder, :trig_awdis_foi],
                 [:responder, :full_awdis_foi],
                 [:another_responder_in_same_team, :std_awdis_foi],
                 [:another_responder_in_same_team, :trig_awdis_foi],
                 [:another_responder_in_same_team, :full_awdis_foi],
               )}
    end

    describe :request_amends do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:press_officer, :full_ppress_foi],
                 [:private_officer, :full_pprivate_foi]
               )}
    end

    describe :request_further_clearance do
      it {should permit_event_to_be_triggered_only_by(
                   [:disclosure_bmt, :std_unassigned_foi],
                   [:disclosure_bmt, :std_awresp_foi],
                   [:disclosure_bmt, :std_draft_foi],
                   [:disclosure_bmt, :std_draft_foi_in_escalation_period],
                   [:disclosure_bmt, :std_awdis_foi],
                   [:disclosure_bmt, :trig_unassigned_foi],
                   [:disclosure_bmt, :trig_awresp_foi],
                   [:disclosure_bmt, :trig_draft_foi],
                   [:disclosure_bmt, :trig_pdacu_foi],
                   [:disclosure_bmt, :trig_awdis_foi],
                   [:disclosure_bmt, :trig_unassigned_foi_accepted],
                   [:disclosure_bmt, :trig_awresp_foi_accepted],
                   [:disclosure_bmt, :trig_draft_foi_accepted],
                   [:disclosure_bmt, :trig_pdacu_foi_accepted],
                 )
      }
    end

    describe :respond do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:responder, :std_awdis_foi],
                 [:responder, :trig_awdis_foi],
                 [:responder, :full_awdis_foi],
                 [:another_responder_in_same_team, :std_awdis_foi],
                 [:another_responder_in_same_team, :trig_awdis_foi],
                 [:another_responder_in_same_team, :full_awdis_foi]
               )}
    end

    describe :take_on_for_approval do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:press_officer, :std_unassigned_foi],
                 [:press_officer, :std_awresp_foi],
                 [:press_officer, :std_draft_foi],
                 [:press_officer, :std_draft_foi_in_escalation_period],
                 [:press_officer, :std_awdis_foi],
                 [:press_officer, :trig_unassigned_foi],
                 [:press_officer, :trig_unassigned_foi_accepted],
                 [:press_officer, :trig_awresp_foi],
                 [:press_officer, :trig_awresp_foi_accepted],
                 [:press_officer, :trig_draft_foi],
                 [:press_officer, :trig_draft_foi_accepted],
                 [:press_officer, :trig_awdis_foi],

                 [:private_officer, :std_unassigned_foi],
                 [:private_officer, :std_awresp_foi],
                 [:private_officer, :std_draft_foi],
                 [:private_officer, :std_draft_foi_in_escalation_period],
                 [:private_officer, :std_awdis_foi],
                 [:private_officer, :trig_unassigned_foi],
                 [:private_officer, :trig_unassigned_foi_accepted],
                 [:private_officer, :trig_awresp_foi],
                 [:private_officer, :trig_awresp_foi_accepted],
                 [:private_officer, :trig_draft_foi],
                 [:private_officer, :trig_draft_foi_accepted],
                 [:private_officer, :trig_awdis_foi],

                 # another approver and approver are permitted here since the policy allows
                 # any team that has not taken the case on to take it on
                 [:another_disclosure_specialist, :std_unassigned_foi],
                 [:another_disclosure_specialist, :std_awresp_foi],
                 [:another_disclosure_specialist, :std_draft_foi],
                 [:another_disclosure_specialist, :std_draft_foi_in_escalation_period],
                 [:another_disclosure_specialist, :std_awdis_foi],
                 [:another_disclosure_specialist, :trig_unassigned_foi],
                 [:another_disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:another_disclosure_specialist, :trig_awresp_foi],
                 [:another_disclosure_specialist, :trig_awresp_foi_accepted],
                 [:another_disclosure_specialist, :trig_draft_foi],
                 [:another_disclosure_specialist, :trig_draft_foi_accepted],
                 [:another_disclosure_specialist, :trig_awdis_foi],
                 [:another_disclosure_specialist, :full_unassigned_foi],
                 [:another_disclosure_specialist, :full_awresp_foi],
                 [:another_disclosure_specialist, :full_awresp_foi_accepted],
                 [:another_disclosure_specialist, :full_draft_foi],

                 [:disclosure_specialist_coworker, :std_unassigned_foi],
                 [:disclosure_specialist_coworker, :std_awresp_foi],
                 [:disclosure_specialist_coworker, :std_draft_foi],
                 [:disclosure_specialist_coworker, :std_draft_foi_in_escalation_period],
                 [:disclosure_specialist_coworker, :std_awdis_foi],

                 [:disclosure_specialist, :std_unassigned_foi],
                 [:disclosure_specialist, :std_awresp_foi],
                 [:disclosure_specialist, :std_draft_foi],
                 [:disclosure_specialist, :std_draft_foi_in_escalation_period],
                 [:disclosure_specialist, :std_awdis_foi],
               )
      }
    end

    describe :update_closure do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_closed_foi],
                 [:disclosure_bmt, :trig_closed_foi],
                 [:disclosure_bmt, :full_closed_foi],
               )}
    end

    describe :unaccept_approver_assignment do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist, :trig_awresp_foi_accepted],
                 [:disclosure_specialist, :trig_draft_foi_accepted],
                 [:disclosure_specialist, :trig_pdacu_foi_accepted],
                 [:disclosure_specialist, :full_awdis_foi],

                 [:press_officer, :full_awdis_foi],

                 [:private_officer, :full_awdis_foi],
               ) }
    end

    describe :unflag_for_clearance do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :trig_unassigned_foi],
                 [:disclosure_specialist, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist, :trig_awresp_foi],
                 [:disclosure_specialist, :trig_awresp_foi_accepted],
                 [:disclosure_specialist, :trig_draft_foi],
                 [:disclosure_specialist, :trig_draft_foi_accepted],
                 [:disclosure_specialist, :trig_pdacu_foi],
                 [:disclosure_specialist, :trig_pdacu_foi_accepted],

                 [:disclosure_specialist_coworker, :trig_unassigned_foi],
                 [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_awresp_foi],
                 [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_draft_foi],
                 [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi],
                 [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],


                 [:press_officer, :full_unassigned_foi],
                 [:press_officer, :full_awresp_foi],
                 [:press_officer, :full_awresp_foi_accepted],
                 [:press_officer, :full_draft_foi],
                 [:press_officer, :full_pdacu_foi_accepted],
                 [:press_officer, :full_pdacu_foi_unaccepted],
                 [:press_officer, :full_ppress_foi],
                 [:press_officer, :full_pprivate_foi],
                 [:press_officer, :full_awdis_foi],

                 [:private_officer, :full_unassigned_foi],
                 [:private_officer, :full_awresp_foi],
                 [:private_officer, :full_awresp_foi_accepted],
                 [:private_officer, :full_draft_foi],
                 [:private_officer, :full_pdacu_foi_accepted],
                 [:private_officer, :full_pdacu_foi_unaccepted],
                 [:private_officer, :full_ppress_foi],
                 [:private_officer, :full_pprivate_foi],
                 [:private_officer, :full_awdis_foi],
               )
      }
    end

    describe :upload_response_and_approve do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :full_pdacu_foi_accepted],
                 [:disclosure_specialist, :trig_pdacu_foi_accepted],
               )
      }
    end

    describe :upload_response_and_return_for_redraft do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :full_pdacu_foi_accepted],
                 [:disclosure_specialist, :trig_pdacu_foi_accepted],
               )
      }
    end

    describe :upload_response_approve_and_bypass do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_specialist, :full_pdacu_foi_accepted],
               )
      }
    end

  ############## EMAIL TESTS ################


    describe :add_message_to_case do
      it {
        should have_after_hook(
          [:disclosure_bmt, :std_draft_foi],
          [:disclosure_bmt, :std_draft_foi_in_escalation_period],
          [:disclosure_bmt, :std_awdis_foi],
          [:disclosure_bmt, :std_responded_foi],
          [:disclosure_bmt, :trig_draft_foi],
          [:disclosure_bmt, :trig_pdacu_foi],
          [:disclosure_bmt, :trig_awdis_foi],
          [:disclosure_bmt, :trig_responded_foi],
          [:disclosure_bmt, :full_draft_foi],
          [:disclosure_bmt, :full_ppress_foi],
          [:disclosure_bmt, :full_pprivate_foi],
          [:disclosure_bmt, :full_awdis_foi],
          [:disclosure_bmt, :full_responded_foi],
          [:disclosure_bmt, :trig_draft_foi_accepted],
          [:disclosure_bmt, :trig_pdacu_foi_accepted],
          [:disclosure_bmt, :full_pdacu_foi_accepted],
          [:disclosure_bmt, :full_pdacu_foi_unaccepted],

          [:disclosure_specialist, :trig_draft_foi],
          [:disclosure_specialist, :trig_pdacu_foi],
          [:disclosure_specialist, :trig_awdis_foi],
          [:disclosure_specialist, :trig_responded_foi],
          [:disclosure_specialist, :trig_draft_foi_accepted],
          [:disclosure_specialist, :trig_pdacu_foi_accepted],
          [:disclosure_specialist, :full_draft_foi],
          [:disclosure_specialist, :full_ppress_foi],
          [:disclosure_specialist, :full_pprivate_foi],
          [:disclosure_specialist, :full_awdis_foi],
          [:disclosure_specialist, :full_responded_foi],
          [:disclosure_specialist, :full_pdacu_foi_accepted],
          [:disclosure_specialist, :full_pdacu_foi_unaccepted],

          [:disclosure_specialist_coworker, :trig_draft_foi],
          [:disclosure_specialist_coworker, :trig_pdacu_foi],
          [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
          [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
          [:disclosure_specialist_coworker, :full_draft_foi],
          [:disclosure_specialist_coworker, :full_ppress_foi],
          [:disclosure_specialist_coworker, :full_pprivate_foi],
          [:disclosure_specialist_coworker, :full_responded_foi],
          [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
          [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],

          [:another_disclosure_specialist, :trig_draft_foi],
          [:another_disclosure_specialist, :trig_draft_foi_accepted],
          [:another_disclosure_specialist, :trig_pdacu_foi],
          [:another_disclosure_specialist, :trig_pdacu_foi_accepted],

          [:responder, :std_draft_foi],
          [:responder, :std_draft_foi_in_escalation_period],
          [:responder, :std_awdis_foi],
          [:responder, :std_responded_foi],
          [:responder, :trig_draft_foi],
          [:responder, :trig_pdacu_foi],
          [:responder, :trig_awdis_foi],
          [:responder, :trig_responded_foi],
          [:responder, :trig_draft_foi_accepted],
          [:responder, :trig_pdacu_foi_accepted],
          [:responder, :full_draft_foi],
          [:responder, :full_ppress_foi],
          [:responder, :full_pprivate_foi],
          [:responder, :full_awdis_foi],
          [:responder, :full_responded_foi],
          [:responder, :full_pdacu_foi_accepted],
          [:responder, :full_pdacu_foi_unaccepted],

          [:another_responder_in_same_team, :std_draft_foi],
          [:another_responder_in_same_team, :std_draft_foi_in_escalation_period],
          [:another_responder_in_same_team, :std_awdis_foi],
          [:another_responder_in_same_team, :std_responded_foi],
          [:another_responder_in_same_team, :trig_draft_foi],
          [:another_responder_in_same_team, :trig_draft_foi_accepted],
          [:another_responder_in_same_team, :trig_pdacu_foi],
          [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
          [:another_responder_in_same_team, :trig_awdis_foi],
          [:another_responder_in_same_team, :trig_responded_foi],
          [:another_responder_in_same_team, :full_draft_foi],
          [:another_responder_in_same_team, :full_ppress_foi],
          [:another_responder_in_same_team, :full_pprivate_foi],
          [:another_responder_in_same_team, :full_awdis_foi],
          [:another_responder_in_same_team, :full_responded_foi],
          [:another_responder_in_same_team, :full_pdacu_foi_accepted],
          [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],

          [:press_officer, :trig_draft_foi],
          [:press_officer, :trig_pdacu_foi],
          [:press_officer, :trig_draft_foi_accepted],
          [:press_officer, :trig_pdacu_foi_accepted],
          [:press_officer, :full_awdis_foi],
          [:press_officer, :full_draft_foi],
          [:press_officer, :full_ppress_foi],
          [:press_officer, :full_pprivate_foi],
          [:press_officer, :full_responded_foi],
          [:press_officer, :full_pdacu_foi_accepted],
          [:press_officer, :full_pdacu_foi_unaccepted],

          [:private_officer, :trig_draft_foi],
          [:private_officer, :trig_pdacu_foi],
          [:private_officer, :trig_draft_foi_accepted],
          [:private_officer, :trig_pdacu_foi_accepted],
          [:private_officer, :full_awdis_foi],
          [:private_officer, :full_draft_foi],
          [:private_officer, :full_ppress_foi],
          [:private_officer, :full_pprivate_foi],
          [:private_officer, :full_responded_foi],
          [:private_officer, :full_pdacu_foi_accepted],
          [:private_officer, :full_pdacu_foi_unaccepted],

       ).with_hook('Workflows::Hooks', :notify_responder_message_received)
      }
    end

    describe :upload_response_and_return_for_redraft do
      it {
        should have_after_hook(
          [:disclosure_specialist, :full_pdacu_foi_accepted],
          [:disclosure_specialist, :trig_pdacu_foi_accepted],
       ).with_hook('Workflows::Hooks', :notify_responder_redraft_requested)
      }
    end

    describe :reassign_user do
      it {
        should have_after_hook(
          [:disclosure_specialist, :trig_unassigned_foi_accepted],
          [:disclosure_specialist, :trig_awresp_foi],
          [:disclosure_specialist, :trig_awresp_foi_accepted],
          [:disclosure_specialist, :trig_draft_foi],
          [:disclosure_specialist, :trig_draft_foi_accepted],
          [:disclosure_specialist, :trig_pdacu_foi],
          [:disclosure_specialist, :trig_pdacu_foi_accepted],
          [:disclosure_specialist, :trig_awdis_foi],
          [:disclosure_specialist, :full_awresp_foi],
          [:disclosure_specialist, :full_awresp_foi_accepted],
          [:disclosure_specialist, :full_draft_foi],
          [:disclosure_specialist, :full_pdacu_foi_accepted],
          [:disclosure_specialist, :full_pdacu_foi_unaccepted],
          [:disclosure_specialist, :full_ppress_foi],
          [:disclosure_specialist, :full_pprivate_foi],
          [:disclosure_specialist, :full_awdis_foi],


          [:disclosure_specialist_coworker, :trig_unassigned_foi_accepted],
          [:disclosure_specialist_coworker, :trig_awresp_foi],
          [:disclosure_specialist_coworker, :trig_awresp_foi_accepted],
          [:disclosure_specialist_coworker, :trig_draft_foi],
          [:disclosure_specialist_coworker, :trig_draft_foi_accepted],
          [:disclosure_specialist_coworker, :trig_pdacu_foi],
          [:disclosure_specialist_coworker, :trig_pdacu_foi_accepted],
          [:disclosure_specialist_coworker, :trig_awdis_foi],
          [:disclosure_specialist_coworker, :full_awresp_foi],
          [:disclosure_specialist_coworker, :full_awresp_foi_accepted],
          [:disclosure_specialist_coworker, :full_draft_foi],
          [:disclosure_specialist_coworker, :full_pdacu_foi_accepted],
          [:disclosure_specialist_coworker, :full_pdacu_foi_unaccepted],
          [:disclosure_specialist_coworker, :full_ppress_foi],
          [:disclosure_specialist_coworker, :full_pprivate_foi],
          [:disclosure_specialist_coworker, :full_awdis_foi],

          [:another_disclosure_specialist, :trig_awresp_foi],
          [:another_disclosure_specialist, :trig_awresp_foi_accepted],
          [:another_disclosure_specialist, :trig_draft_foi],
          [:another_disclosure_specialist, :trig_draft_foi_accepted],
          [:another_disclosure_specialist, :trig_pdacu_foi],
          [:another_disclosure_specialist, :trig_pdacu_foi_accepted],
          [:another_disclosure_specialist, :full_awresp_foi],
          [:another_disclosure_specialist, :full_awresp_foi_accepted],
          [:another_disclosure_specialist, :full_draft_foi],
          [:another_disclosure_specialist, :full_pdacu_foi_accepted],
          [:another_disclosure_specialist, :full_pdacu_foi_unaccepted],

          [:responder, :std_draft_foi],
          [:responder, :std_draft_foi_in_escalation_period],
          [:responder, :std_awdis_foi],
          [:responder, :trig_draft_foi],
          [:responder, :trig_draft_foi_accepted],
          [:responder, :trig_pdacu_foi],
          [:responder, :trig_pdacu_foi_accepted],
          [:responder, :trig_awdis_foi],
          [:responder, :full_draft_foi],
          [:responder, :full_pdacu_foi_accepted],
          [:responder, :full_pdacu_foi_unaccepted],
          [:responder, :full_ppress_foi],
          [:responder, :full_pprivate_foi],
          [:responder, :full_awdis_foi],

          [:another_responder_in_same_team, :std_draft_foi],
          [:another_responder_in_same_team, :std_draft_foi_in_escalation_period],
          [:another_responder_in_same_team, :std_awdis_foi],
          [:another_responder_in_same_team, :trig_draft_foi],
          [:another_responder_in_same_team, :trig_draft_foi_accepted],
          [:another_responder_in_same_team, :trig_pdacu_foi],
          [:another_responder_in_same_team, :trig_pdacu_foi_accepted],
          [:another_responder_in_same_team, :trig_awdis_foi],
          [:another_responder_in_same_team, :full_draft_foi],
          [:another_responder_in_same_team, :full_pdacu_foi_accepted],
          [:another_responder_in_same_team, :full_pdacu_foi_unaccepted],
          [:another_responder_in_same_team, :full_ppress_foi],
          [:another_responder_in_same_team, :full_pprivate_foi],
          [:another_responder_in_same_team, :full_awdis_foi],

          [:press_officer, :trig_awresp_foi],
          [:press_officer, :trig_awresp_foi_accepted],
          [:press_officer, :trig_draft_foi],
          [:press_officer, :trig_draft_foi_accepted],
          [:press_officer, :trig_pdacu_foi],
          [:press_officer, :trig_pdacu_foi_accepted],
          [:press_officer, :full_awresp_foi],
          [:press_officer, :full_awresp_foi_accepted],
          [:press_officer, :full_draft_foi],
          [:press_officer, :full_pdacu_foi_accepted],
          [:press_officer, :full_pdacu_foi_unaccepted],
          [:press_officer, :full_ppress_foi],
          [:press_officer, :full_pprivate_foi],
          [:press_officer, :full_awdis_foi],
          [:press_officer, :full_unassigned_foi],

          [:private_officer, :trig_awresp_foi],
          [:private_officer, :trig_awresp_foi_accepted],
          [:private_officer, :trig_draft_foi],
          [:private_officer, :trig_draft_foi_accepted],
          [:private_officer, :trig_pdacu_foi],
          [:private_officer, :trig_pdacu_foi_accepted],
          [:private_officer, :full_awresp_foi],
          [:private_officer, :full_awresp_foi_accepted],
          [:private_officer, :full_draft_foi],
          [:private_officer, :full_pdacu_foi_accepted],
          [:private_officer, :full_pdacu_foi_unaccepted],
          [:private_officer, :full_ppress_foi],
          [:private_officer, :full_pprivate_foi],
          [:private_officer, :full_awdis_foi],
          [:private_officer, :full_unassigned_foi],
       ).with_hook('Workflows::Hooks', :reassign_user_email)
      }
    end

    describe :approve do
      it {
        should have_after_hook(
          [:disclosure_specialist, :trig_pdacu_foi_accepted]
       ).with_hook('Workflows::Hooks', :notify_responder_ready_to_send)
      }
    end

    describe :assign_responder do
      it {
        should have_after_hook(
          [:disclosure_bmt, :std_unassigned_foi],
          [:disclosure_bmt, :trig_unassigned_foi],
          [:disclosure_bmt, :trig_unassigned_foi_accepted],
          [:disclosure_bmt, :full_unassigned_foi],
       ).with_hook('Workflows::Hooks', :assign_responder_email)
      }
    end

    describe :assign_to_new_team do
      it {
        should have_after_hook(
          [:disclosure_bmt, :std_awresp_foi],
          [:disclosure_bmt, :std_draft_foi],
          [:disclosure_bmt, :std_draft_foi_in_escalation_period],
          [:disclosure_bmt, :trig_awresp_foi],
          [:disclosure_bmt, :trig_awresp_foi_accepted],
          [:disclosure_bmt, :trig_draft_foi],
          [:disclosure_bmt, :trig_draft_foi_accepted],
          [:disclosure_bmt, :full_awresp_foi],
          [:disclosure_bmt, :full_awresp_foi_accepted],
          [:disclosure_bmt, :full_draft_foi],
       ).with_hook('Workflows::Hooks', :assign_responder_email)
      }
    end

    describe :upload_response_and_approve do
      it {
        should have_after_hook(
          [:disclosure_specialist, :trig_pdacu_foi_accepted]
       ).with_hook('Workflows::Hooks', :notify_responder_ready_to_send)
      }
    end

    describe :upload_response_approve_and_bypass do
      it {
        should have_after_hook(
          [:disclosure_specialist, :full_pdacu_foi_accepted],
       ).with_hook('Workflows::Hooks', :notify_responder_ready_to_send)
      }
    end

  end

  context 'with cases closed the old way' do
    before(:all) do
      DbHousekeeping.clean
      @setup = StandardSetup.new(
        only_cases: [
          :std_closed_foi,
          :std_old_closed_foi,
          :trig_closed_foi,
          :trig_old_closed_foi,
          :full_closed_foi,
          :full_old_closed_foi,
        ]
      )
    end

    after(:all) { DbHousekeeping.clean }

    describe :update_closure do
      it {
        should permit_event_to_be_triggered_only_by(
                 [:disclosure_bmt, :std_closed_foi],
                 [:disclosure_bmt, :trig_closed_foi],
                 [:disclosure_bmt, :full_closed_foi],
               )
      }
    end
  end
end
