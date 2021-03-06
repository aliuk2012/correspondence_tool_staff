# == Schema Information
#
# Table name: cases_users_transitions_trackers
#
#  id                 :integer          not null, primary key
#  case_id            :integer
#  user_id            :integer
#  case_transition_id :integer
#

require "rails_helper"

describe CasesUsersTransitionsTracker do
  let(:kase)    { create :accepted_case }
  let(:user)    { kase.responder }
  let(:tracker) { CasesUsersTransitionsTracker.create case: kase,
                                                      user: user  }
  describe 'uniqueness validation' do
    it 'prevents two records for that same case id and user id being created ' do
      expect {
        CasesUsersTransitionsTracker.create!(case: tracker.case, user: tracker.user)
      }.to raise_error ActiveRecord::RecordInvalid, 'Validation failed: User has already been taken'
    end
  end

  describe '.sync_for_case_and_user' do
    context 'tracker exists for given case and user' do
      before do
        tracker
      end

      it 'does not create a new tracker' do
        expect(kase.users_transitions_trackers.where(user: user).count).to eq 1
      end

      context 'case has messages' do
        let!(:message) { create :case_transition_add_message_to_case, case: kase }

        it 'updates the existing tracker' do
          CasesUsersTransitionsTracker.sync_for_case_and_user(kase, user)
          tracker.reload
          expect(tracker.case_transition_id).to eq message.id
        end
      end

      context 'case has no messages' do
        it 'does not update the tracker' do
          CasesUsersTransitionsTracker.sync_for_case_and_user(kase, user)
          tracker.reload
          expect(tracker.case_transition_id).to eq nil
        end
      end
    end
  end

  context 'tracker does not exists for given case and user' do
    context 'case has messages' do
      let!(:message) { create :case_transition_add_message_to_case, case: kase }

      it 'creates a new tracker' do
        expect(kase.users_transitions_trackers.where(user: user).count)
          .to eq 0
        CasesUsersTransitionsTracker.sync_for_case_and_user(kase, user)
        expect(kase.users_transitions_trackers.where(user: user).count)
          .to eq 1
      end

      it 'sets the transition id on the new tracker' do
        CasesUsersTransitionsTracker.sync_for_case_and_user(kase, user)
        new_tracker = CasesUsersTransitionsTracker.find_by case: kase,
                                                           user: user
        expect(new_tracker.case_transition_id).to eq kase.transitions.last.id
      end
    end

    context 'case has no messages' do
      it 'does not create a new tracker' do
        CasesUsersTransitionsTracker.sync_for_case_and_user(kase, user)
        expect(kase.users_transitions_trackers.where(user: user).count)
          .to eq 0
      end
    end
  end
end
