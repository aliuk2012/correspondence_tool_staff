module CTS
  class Cases < Thor
    include Thor::Rails unless SKIP_RAILS

    default_command :list

    desc 'assign CASE TEAM [USER]', 'Assign a case a user'
    def assign(*args)
      case_id_or_number = args.shift
      if case_id_or_number.blank?
        error 'case not provided'
        help
        exit 1
      end
      team_id_or_name = args.shift
      if team_id_or_name.blank?
          error 'team not provided'
          help
          exit 1
      end
      user_id_or_name = args.shift

      kase = CTS::find_case(case_id_or_number)
      team = CTS::find_team(team_id_or_name)
      if user_id_or_name.present?
        user = CTS::find_user(user_id_or_name)
        role = team.user_roles.find_by(user: user).role
      else
        user = team.users.first
        role = { 'responder' => 'responding',
                 'manager'   => 'managing',
                 'approver'  => 'approving' }[team.user_roles.first.role]
      end


      assign_command = Cases::Assign.new(kase, user, team, role)
      assign_command.call
    end

    desc "clear", "Delete all cases in the database"
    def clear
      CTS::check_environment
      puts "Deleting all cases"
      Case.all.map(&:destroy)
    end

    desc 'demo', 'Create a demo set of cases for stats reporting purposes'
    option :number, aliases: 'n', type: :numeric,
           desc: 'Number of cases to create (per state). [1]'
    def demo
      parse_options
      CTS::check_environment
      require File.join(File.dirname(__FILE__), '/demo_setup')
      CTS::DemoSetup.new(@number_to_create).run
    end

    desc 'create OPTIONS all|<states>', 'Create cases in the specified states'
    long_desc <<~LONGDESC

    The create command takes the following sub commands:
     - all:        Create a number of cases in all states
     - <states>:   Create a number of cases in the specified state(s)

     Multiple states can be specified.

     Valid states are as follows:
        unassigned
        flagged_for_dacu_clearance
        awaiting_responder
        approver_assignment_accepted
        drafting
        pending_dacu_clearance
        awaiting_dispatch
        responded
        closed

    Examples:
      ./cts cases create --created-at='2017-06-20 09:36:00' drafting
      ./cts cases create -x -n2 all
      ./cts cases create --dry-run -p awaiting_responder
    LONGDESC

    option :number, aliases: 'n', type: :numeric,
           desc: 'Number of cases to create (per state). [1]'
    option :dacu_disclosure, aliases: 'd', type: :boolean,
           desc: 'Flag cases for clearance by DACU Disclosure.'
    option :press_office, aliases: 'p', type: :boolean,
           desc: 'Flag cases for clearance by Press Office.'
    option :clear, aliases: :x, type: :boolean,
           desc: 'Clear existing cases before creating.'
    option :dry_run, type: :boolean,
           desc: 'Print out what states cases will be created in.'
    option :responder, aliases: :r, type: :string,
           desc: 'ID or name of responder to use for case assignments.'
    option :responding_team, aliases: :t, type: :string,
           desc: 'ID or name of responding team to use for case assignments.'
    option :created_at, type: :string
    # option :dacu_manager, type: :string
    # option :dacu_approver, type: :string
    def create(*args)
      cmd = CTS::Cases::Create.new(self, options, args)
      cmd.call
    end

    desc 'list', 'List cases in the system.'
    def list
      columns = [
        :id,
        :number,
        :subject,
        :current_state,
        :requires_clearance?
      ]
      tp Case.all, columns
    end

    desc 'show', 'Show case details.'
    def show(*args)
      args.each do |case_identifier|
        kase = CTS::find_case(case_identifier)
        ap kase

        puts "\nAssignments:"
        tp kase.assignments, [:id, :state, :role, :team_id, :user_id]

        puts "\nTransitions:"
        tp kase.transitions, :id, :event, :to_state, :user_id,
           metadata: { width: 40 }

        puts "\nAttachments:"
        tp kase.attachments, [:id, :type, :key, :preview_key]
      end
    end
  end
end
