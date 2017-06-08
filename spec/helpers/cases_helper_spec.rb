require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the CasesHelper. For example:
#
# describe CasesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe CasesHelper, type: :helper do

  let(:manager)   { create :manager }
  let(:responder) { create :responder }
  let(:coworker)  { create :responder,
                           responding_teams: responder.responding_teams }
  let(:another_responder) { create :responder }

  describe '#action_button_for(event)' do

    context 'when event == :assign_responder' do
      it 'generates HTML that links to the new assignment page' do
        @case = create(:case)
        expect(action_button_for(:assign_responder)).to eq(
          "<a id=\"action--assign-to-responder\" class=\"button\" href=\"/cases/#{@case.id}/assignments/new\">Assign to a responder</a>")
      end
    end

    context 'when event == :close' do
      it 'generates HTML that links to the close case action' do
        @case = create(:responded_case)
        expect(action_button_for(:close)).to eq(
"<a id=\"action--close-case\" class=\"button\" data-method=\"get\" \
href=\"/cases/#{@case.id}/close\">Close case</a>"
          )
      end
    end

    context 'when event == :add_responses' do
      context 'case does not require clearance' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:accepted_case)
          expect(@case).to receive(:requires_clearance?).and_return(false)
          expect(action_button_for(:add_responses)).to eq(
             "<a id=\"action--upload-response\" class=\"button\" href=\"/cases/#{@case.id}/new_response_upload?action=upload\">Upload response</a>"
            )
        end
      end

      context 'case requires clearance' do
        it 'generates HTML that links to the upload response page' do
          @case = create(:accepted_case)
          expect(@case).to receive(:requires_clearance?).and_return(true)
          expect(action_button_for(:add_responses)).to eq(
           "<a id=\"action--upload-response\" class=\"button\" href=\"/cases/#{@case.id}/new_response_upload?action=upload-flagged\">Upload response</a>"
         )
        end
      end

    end

    context 'when event = ":respond' do
      it 'generates HTML that links to the upload response page' do
        @case = create(:case_with_response)
        expect(action_button_for(:respond)).to eq(
"<a id=\"action--mark-response-as-sent\" class=\"button\" \
href=\"/cases/#{@case.id}/respond\">Mark response as sent</a>"
          )
      end
    end
  end






end
