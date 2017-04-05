require 'rails_helper'

feature 'Assigning a case from the detail view' do
  given(:kase)            { create(:case) }
  given(:responder)       { create(:responder) }
  given(:responding_team) { create :responding_team, responders: [responder] }
  given(:manager)         { create(:manager)  }
  given(:managing_team)   { create :managing_team, managers: [manager] }
  given(:assignment)      { kase.responder_assignment }

  before do
    responding_team
  end

  scenario 'assigning a new case' do
    login_as manager
    visit case_path(kase)
    expect(cases_show_page).to(
      have_link('Assign to a responder', href: new_case_assignment_path(kase))
    )

    click_link 'Assign to a responder'
    expect(assign_page).to have_content('Assign case')

    choose responding_team.name
    click_button 'Assign case'
    expect(current_path).to eq cases_path
    expect(page).to have_content('Case successfully assigned')

    newest_assignment = Assignment.last

    kase.reload
    expect(kase.current_state).to eq 'awaiting_responder'
    expect(kase.assignments).to include newest_assignment

    expect(newest_assignment).to have_attributes(
                                   role:    'responding',
                                   team:    responding_team,
                                   user_id: nil,
                                   case:    kase,
                                   state:   'pending'
                                 )
  end

  context 'case has been rejected' do
    given(:kase) { create(:assigned_case) }

    before do
      responding_team
      assignment.reject responder, 'No thanks'
    end

    scenario 'assigner reassigns rejected case' do

      login_as manager
      visit case_path(kase)
      expect(cases_show_page).to(
        have_link('Assign to a responder', href: new_case_assignment_path(kase))
      )

      click_link 'Assign to a responder'
      expect(page).to have_content('Assign case')

      choose responding_team.name
      click_button 'Assign case'
      expect(current_path).to eq cases_path
      expect(page).to have_content('Case successfully assigned')

      newest_assignment = Assignment.last

      kase.reload
      expect(kase.current_state).to eq 'awaiting_responder'
      expect(kase.assignments).to include newest_assignment

      expect(newest_assignment).to have_attributes(
                                     role:    'responding',
                                     team:    responding_team,
                                     user_id: nil,
                                     case:    kase,
                                     state:   'pending'
                                   )
    end

  end
end
