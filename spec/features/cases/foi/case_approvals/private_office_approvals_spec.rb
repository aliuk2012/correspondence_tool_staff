require 'rails_helper'

feature 'cases requiring clearance by press office' do
  given!(:dacu_disclosure)             { find_or_create :team_dacu_disclosure }
  given(:disclosure_specialist)        { create :disclosure_specialist }
  given(:other_disclosure_specialist)  { create :disclosure_specialist }
  given!(:press_office)                { find_or_create :team_press_office }
  given!(:press_officer)               { create :press_officer,
                                                full_name: 'Preston Offman' }
  given!(:private_office)              { find_or_create :team_private_office }
  given!(:private_officer)             { create :private_officer }
  given(:other_private_officer)        { create :private_officer }
  given(:case_available_for_taking_on) { create :case_being_drafted,
                                                created_at: 1.business_day.ago }
  given(:pending_dacu_clearance_case) do
    create :pending_dacu_clearance_case,
           :flagged_accepted,
           :press_office,
           disclosure_assignment_state: 'accepted',
           disclosure_specialist: disclosure_specialist
  end
  given(:pending_press_clearance_case)   { create :pending_press_clearance_case,
                                                  :private_office }
  given(:pending_private_clearance_case) { create :pending_private_clearance_case }

  scenario 'Private Officer taking on a case', js: true do
    case_available_for_taking_on
    login_as private_officer
    incoming_cases_page.load

    case_row = incoming_cases_page.case_list.first
    expect(case_row.number).to have_text case_available_for_taking_on.number
    case_row.actions.take_on_case.click
    expect(case_row.actions.success_message).to have_text 'Case taken on'

    case_row.number.click
    expect(cases_show_page.case_history.entries.first)
      .to have_text('Preston Offman Take on for approval')
    expect(cases_show_page.case_history.entries[1])
      .to have_text("#{private_officer.full_name} Flag for clearance")

    _case_not_for_private_office_open_cases = create :case_being_drafted,
                                                     :flagged_accepted,
                                                     :press_office
    open_cases_page.load
    expect(open_cases_page.case_list.first.number)
      .to have_text case_available_for_taking_on.number
    expect(open_cases_page.case_list.count).to eq 1
  end

  scenario 'Press Officer approves a case that requires Private Office approval' do
    login_as press_officer
    cases_show_page.load(id: pending_press_clearance_case.id)

    approve_case kase: pending_press_clearance_case,
                 expected_team: private_office,
                 expected_status: 'Pending clearance'
    approve_response kase: pending_press_clearance_case
    select_case_on_open_cases_page kase: pending_press_clearance_case,
                                   expected_team: private_office
  end

  scenario 'Private Officer approves a case' do
    login_as private_officer

    cases_show_page.load(id: pending_private_clearance_case.id)
    expect(cases_show_page.case_status.details.who_its_with.text)
      .to eq 'Private Office'

    approve_case kase: pending_private_clearance_case,
                 expected_team: pending_private_clearance_case.responding_team,
                 expected_status: 'Ready to send'
    approve_response kase: pending_private_clearance_case
    select_case_on_open_cases_page(
      kase: pending_private_clearance_case,
      expected_team: pending_private_clearance_case.responding_team
    )
  end

  scenario 'different Private Officer from same team approving a case' do
    login_as other_private_officer

    cases_show_page.load(id: pending_private_clearance_case.id)
    approve_case kase: pending_private_clearance_case,
                 expected_team: pending_private_clearance_case.responding_team,
                 expected_status: 'Ready to send'
    approve_response kase: pending_private_clearance_case
    select_case_on_open_cases_page(
      kase: pending_private_clearance_case,
      expected_team: pending_private_clearance_case.responding_team
    )
  end
end