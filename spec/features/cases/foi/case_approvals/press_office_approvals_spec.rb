require 'rails_helper'

feature 'cases requiring clearance by press office' do
  given(:disclosure_specialist) { create :disclosure_specialist }
  given(:press_officer)         { create :press_officer }
  given(:other_press_officer)   { create :press_officer }
  given(:press_office)          { find_or_create :team_press_office }
  given(:pending_dacu_clearance_case) do
    create :pending_dacu_clearance_case,
           :flagged_accepted,
           :press_office,
           disclosure_assignment_state: 'accepted',
           disclosure_specialist: disclosure_specialist
  end
  given(:pending_press_clearance_case) { create :pending_press_clearance_case, press_officer: press_officer }

  scenario 'Disclosure Specialist approves a case that requires Press Office approval' do
    login_as disclosure_specialist
    cases_show_page.load(id: pending_dacu_clearance_case.id)
    cases_show_page.actions.clear_case.click

    expect(approve_response_page)
      .to be_displayed(id: pending_dacu_clearance_case.id)
    expect(approve_response_page.clearance.expectations.team.text)
      .to eq 'Press Office'
    expect(approve_response_page.clearance.expectations.status.text)
      .to eq 'Pending clearance'
    approve_response_page.submit_button.click

    expect(open_cases_page).to be_displayed
    kase = pending_dacu_clearance_case
    expect(open_cases_page.notices.first)
      .to have_text "You have cleared case #{kase.number} - #{kase.subject}"
    open_cases_page.click_on kase.number

    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Press Office'
  end

  scenario 'Press Officer approves a case' do
    login_as press_officer

    cases_show_page.load(id: pending_press_clearance_case.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Press Office'

    cases_show_page.actions.clear_case.click
    expect(approve_response_page)
      .to be_displayed(id: pending_press_clearance_case.id)
    expect(approve_response_page.clearance.expectations.team.text)
      .to eq pending_press_clearance_case.responding_team.name
    expect(approve_response_page.clearance.expectations.status.text)
      .to eq 'Ready to send'

    approve_response_page.submit_button.click
    expect(open_cases_page).to be_displayed
    kase = pending_press_clearance_case
    expect(open_cases_page.notices.first)
      .to have_text "You have cleared case #{kase.number} - #{kase.subject}"

    open_cases_page.click_on kase.number
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq pending_press_clearance_case.responding_team.name
  end

  scenario 'different Press Officer from same team approving a case' do
    login_as other_press_officer

    cases_show_page.load(id: pending_press_clearance_case.id)
    cases_show_page.actions.clear_case.click
    approve_response_page.submit_button.click
    expect(open_cases_page).to be_displayed
    kase = pending_press_clearance_case
    expect(open_cases_page.notices.first)
      .to have_text "You have cleared case #{kase.number} - #{kase.subject}"
  end
end
