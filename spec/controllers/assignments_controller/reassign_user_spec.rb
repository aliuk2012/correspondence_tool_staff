require 'rails_helper'

RSpec.describe AssignmentsController, type: :controller do
  let(:responding_team)   { accepted_case.responding_team }
  let(:responder)         { responding_team.responders.first }
  let(:approver)          { create :approver }
  let(:approving_team)    { approver.approving_team }

  let(:accepted_case)     { create :accepted_case }
  let(:accepted_case_trigger) { create :accepted_case, :flagged_accepted,
                                       approver: approver }

  let(:assignment)        { accepted_case.responder_assignment }

  describe 'GET reassign_user' do
    let(:params)     { { case_id: accepted_case.id, id: assignment.id} }

    before(:each) do
      sign_in responder
    end

    it 'authorises' do
      expect {
        get :reassign_user, params: params
      } .to require_permission(:assignments_reassign_user?)
              .with_args(responder, accepted_case)
    end

    it 'renders the page' do
      get :reassign_user, params: params
      expect(response).to render_template :reassign_user
    end

    it 'sets the @team_users' do
      get :reassign_user, params: params
      expect(assigns(:team_users))
        .to eq responding_team.responders.order(:full_name)
    end
  end
end
