module PageObjects
  module Pages
    module Assignments
      class NewPage < SitePrism::Page
        set_url '/cases/{id}/assignments/new'

        section :primary_navigation, PageObjects::Sections::PrimaryNavigationSection, '.global-nav'

      end
    end
  end
end