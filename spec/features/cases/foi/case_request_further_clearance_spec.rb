require "rails_helper"

feature 'Requesting further clearance on an unflagged case' do
  given(:manager)         { create :disclosure_bmt_user }
  given(:case_being_drafted)   { create :case_being_drafted }
  given(:assigned_case) { create :awaiting_responder_case}

  background do
    login_as manager
  end

  scenario 'manager requests clearance on a case with responder' do
    cases_show_page.load(id: case_being_drafted.id)
    expect(cases_show_page.case_details.basic_details.case_type.text).to eq "Case typeFOI"
    cases_show_page.clearance_levels.escalate_link.click
    expect(cases_show_page).to be_displayed
    event_row = cases_show_page.case_history.rows.first
    expect(event_row.details.event.text)
      .to eq 'Request further clearance'
    trigger_details = cases_show_page.case_details.basic_details.case_type.foi_trigger.text
    expect(trigger_details).to eq 'This is a Trigger case'
  end

  scenario 'manager requests clearance on an unaccepted case' do
    cases_show_page.load(id: assigned_case.id)
    expect(cases_show_page.case_details.basic_details.case_type.text).to eq "Case typeFOI"
    cases_show_page.clearance_levels.escalate_link.click
    expect(cases_show_page).to be_displayed
    event_row = cases_show_page.case_history.rows.first
    expect(event_row.details.event.text)
      .to eq 'Request further clearance'
    trigger_details = cases_show_page.case_details.basic_details.case_type.foi_trigger.text
    expect(trigger_details).to eq 'This is a Trigger case'
  end
end