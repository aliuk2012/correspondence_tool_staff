class SideBar < SitePrism::Section
  element :external_deadline, '.external_deadline .case-sidebar__data'
  element :status, '.status .case-sidebar__data'
  element :who_its_with, '.who-its-with .case-sidebar__data'
  element :name, '.name .case-sidebar__data'
  element :requester_type, '.case-sidebar__data--contact .requester-type'
  element :email, '.case-sidebar__data--contact .email'
  element :postal_address, '.case-sidebar__data--contact .postal-address'
  element :actions, '.actions .case-sidebar__data'
  element :mark_as_sent_button, 'a:contains("Mark response as sent")'
end

class CaseHeading < SitePrism::Section
  element :case_number, '.case-heading--secondary'
end

class CaseDetailsPage < SitePrism::Page
  set_url '/cases/{id}'
  element :message, '.request'
  element :received_date, '.request--date-received'
  element :escalation_notice, '.alert-orange'
  section :sidebar, ::SideBar, 'section.case-sidebar'
  section :case_heading, ::CaseHeading, '.case-heading'

  sections :uploaded_files, 'table#uploaded-files tr' do
    element :filename, 'td[aria-label="File name"]'
  end
end
