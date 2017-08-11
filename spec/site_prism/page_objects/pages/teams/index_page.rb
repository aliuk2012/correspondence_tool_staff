module PageObjects
  module Pages
    module Teams
      class IndexPage < SitePrism::Page
        set_url '/teams'

        section :primary_navigation,
                PageObjects::Sections::PrimaryNavigationSection, '.global-nav'


        element :heading, 'h1.page-heading'

        sections :business_groups_list, '.report tbody tr' do
          element :name, 'td[aria-label="Name"] a'
          element :director_general, 'td[aria-label="Director general"]'
          element :directorates, 'td[aria-label="Directorates"]'
          element :actions, 'td[aria-label="Actions"]'
        end

        def row_for_business_group(name)
          business_groups_list.find { |row|
            row.name.text == "View the details of #{ name }"
          }
        end

      end
    end
  end
end

