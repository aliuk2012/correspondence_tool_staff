require 'rails_helper'

feature 'viewing response details' do
  given(:manager)         { create :manager }
  given(:responder)       { responding_team.responders.first }
  given(:responding_team) { create :responding_team }

  context 'as an manager' do
    before do
      login_as manager
    end

    context 'with a case not yet accepted' do
      given(:assigned_case)  { create :assigned_case,
                                      responding_team: responding_team }

      scenario 'when the case has a response' do
        cases_show_page.load(id: assigned_case.id)

        expect(cases_show_page).not_to have_case_attachments
      end
    end

    context 'with a case marked as responded' do
      given(:responded_case) do
        create :responded_case,
               manager: manager,
               responder: responder
      end
      given(:response) { responded_case.attachments.first }

      scenario 'when the case has a response' do
        cases_show_page.load(id: responded_case.id)

        expect(cases_show_page).to have_case_attachments
        expect(cases_show_page.case_attachments.first.filename.text)
          .to eq(response.filename)
        expect(cases_show_page.case_details.responders_details.team.data.text)
          .to eq(responding_team.name)
        expect(cases_show_page.case_details.responders_details.name.data.text)
          .to eq(responder.full_name)
      end

      given(:case_with_many_responses) do
        create :responded_case,
               responses: build_list(:correspondence_response, 4),
               manager: manager,
               responder: responder
      end
      given(:responses) { case_with_many_responses.attachments }

      scenario 'with a case with multiple uploaded responses' do
        responded_case.attachments << build(:case_attachment)
        cases_show_page.load(id: responded_case.id)

        rendered_filenames = cases_show_page.case_attachments
                               .map do |response|
          response.filename.text
        end

        sorted_response_filenames =
          responded_case.attachments.response.map(&:filename).sort
        expect(rendered_filenames).to eq sorted_response_filenames
      end
    end

    context 'with a closed case' do
      given(:closed_case)  { create :closed_case, responder: responder }

      scenario 'when the case has a response' do
        cases_show_page.load(id: closed_case.id)

        response_details = cases_show_page.case_details.response_details

        expect(cases_show_page.case_details).to have_response_details

        expect(cases_show_page.case_details.responders_details.team.data.text)
          .to eq(responding_team.name)

        expect(response_details.date_responded.data.text)
          .to eq(closed_case.date_responded.strftime(Settings.default_date_format))

        expect(response_details.outcome.data.text)
            .to eq(closed_case.outcome.name)
      end
    end

  end

  context 'as a responder' do
    before do
      login_as responder
    end

    context 'with a case being drafted' do
      given(:accepted_case) { create :accepted_case, responder: responder }
      given(:response)      { create :case_response }

      scenario 'when the case has no responses' do
        cases_show_page.load(id: accepted_case.id)
        expect(cases_show_page.case_details).to have_no_response_details
        expect(cases_show_page).to have_no_case_attachments
      end

      scenario 'when the case has a response' do
        accepted_case.attachments << response
        cases_show_page.load(id: accepted_case.id)
        expect(cases_show_page).to have_case_attachments
      end
    end
  end
end
