module PageObjects
  module Sections
    module Cases
      class ClearanceLevelsSection < SitePrism::Section
        element :escalation_deadline, 'p.escalation-deadline'

        section :basic_details, '.basic-details' do

          section :deputy_director, 'tr.deputy-director' do
            element :data, 'td'
          end

          section :dacu_disclosure, 'tr.dacu-disclosure' do
            element :data, 'td'
          end

          sections :non_default_approvers, 'tr.non-default-approvers' do
            element :department_name, 'th'
            element :approver_name, 'td'
          end
        end
      end
    end
  end
end