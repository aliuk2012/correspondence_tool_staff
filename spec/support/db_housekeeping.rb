module DbHousekeeping
  def self.clean(seed: true)
    tables = %w(
      cases
      assignments
      case_attachments
      case_closure_metadata
      case_number_counters
      case_transitions
      cases_exemptions
      feedback
      team_correspondence_type_roles
      team_properties
      teams
      teams_users_roles
      users
      correspondence_types)
    tables.each do |table|
      ActiveRecord::Base.connection.execute("DELETE FROM #{table}")
    end
    seed_database_for_tests if seed
  end
end
