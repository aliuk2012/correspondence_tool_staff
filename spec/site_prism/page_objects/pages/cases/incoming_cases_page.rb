module PageObjects
  module Pages
    module Cases
      class IncomingCasesPage < SitePrism::Page
        set_url '/cases/incoming'

        section :user_card, PageObjects::Sections::UserCardSection, '.user-card'
        sections :case_list, '.case_row' do
          element :number, 'td[aria-label="Case number"]'
          section :request, 'td[aria-label="Request"]' do
            element :name, '.case_name'
            element :subject, '.case_subject'
            element :message, '.case_message_extract'
          end
          section :actions, 'td[aria-label="Actions"]' do
            element :take_on_case, '.button'
            element :success_message, '.action-success'
            element :undo_assign_link, '.action-success a'
            element :de_escalate_link, '.js-de-escalate-link'
            element :undo_de_escalate_link, '.js-undo-de-escalate-link'
          end
        end

        section :service_feedback, PageObjects::Sections::ServiceFeedbackSection, '.feedback'
        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

        def case_numbers
          case_list.map do |row|
            row.number.text.delete('Link to case')
          end
        end
      end
    end
  end
end