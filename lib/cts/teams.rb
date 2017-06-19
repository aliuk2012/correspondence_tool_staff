module CTS
  class Teams < Thor
    include Thor::Rails unless SKIP_RAILS

    desc 'list', 'List teams in the system.'
    option :all, aliases: :a
    def list
      say ::Rails.env
      if options[:all]
        columns = []
      else
        columns = [:id, :name, :email]
      end
      tp Team.all, *columns
    end

    default_command :list

    desc 'seed', 'Seed teams for dev/demo.'
    def seed
      require "#{CTS_ROOT_DIR}/db/seeders/demo_user_seeder"
      seeder = DemoUserSeeder.new
      seeder.seed_teams
    end

    desc 'show', 'Show team details.'
    def show(*args)
      args.each do |team_identifier|
        team = if team_identifier.match(/^\d+$/)
                 Team.where(id: team_identifier).first
               else
                 Team.where(name: team_identifier).first
               end
        puts "\nUsers:"
        tp team.user_roles,
           {user_id: { display_name: :id}},
           {'user.full_name' => { display_name: :full_name}},
           :role
      end
    end
  end
end