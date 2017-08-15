module PageObjects
  module Pages
    module Cases
      class ShowPage < SitePrism::Page
        set_url '/cases/{id}'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        element :escalation_notice, '.alert-orange'
        element :notice, '.notice-summary-heading'

        section :page_heading,
                PageObjects::Sections::PageHeadingSection, '.page-heading'

        section :actions, '.button-holder' do
          element :upload_response, '#action--upload-response'
          element :mark_as_sent, '#action--mark-response-as-sent'
          element :close_case, '#action--close-case'
          element :clear_case, '#action--approve'
          element :request_amends, '#action--request-amends'
          element :upload_approve, '#action--upload-approve'
          element :upload_redraft, '#action--upload-redraft'
          element :reassign_user, '#action--reassign-case'
        end

        section :case_status,
                PageObjects::Sections::Cases::CaseStatusSection, '.case-status'

        section :case_details,
                PageObjects::Sections::Cases::CaseDetailsSection, '.case-details'

        section :clearance_levels,
                PageObjects::Sections::Cases::ClearanceLevelsSection, '.clearance-levels'

        section :request,
                PageObjects::Sections::Cases::CaseRequestSection, '.request'

        sections :case_attachments,
                PageObjects::Sections::Cases::CaseAttachmentSection,
                '.case-attachments-group'

        section :what_do_you_want_to_do,
                PageObjects::Sections::Cases::WhatDoYouWantToDoSection,
                '.what-do-you-want-to-do'

        section :case_history, '#case-history' do
          element :heading, 'thead tr'
          elements :entries, 'tbody tr'
        end
      end

    end
  end
end
