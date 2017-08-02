module CTS
  class Cases
    class Create
      attr_accessor :command, :args, :options

      def initialize(command, options, args)
        @command = command
        @options = options
        @args = args

        parse_options(options)
        CTS::check_environment

        @invalid_params = false
        parse_params(args)
      end

      def call
        puts "Creating #{@number_to_create} cases in each of the following states:"
        puts "\t" + @end_states.join("\n\t")
        puts "Responder is: #{responding_team.name} user #{responder.full_name}"
        puts "Flagging each for DACU Disclosure clearance" if @flag.present?
        puts "Flagging each for Press Office clearance" if @flag == 'press'
        puts "Flagging each for Private Office clearance" if @flag == 'private'
        puts "\n"

        clear if @clear_cases

        cases = []
        begin
          @end_states.map do |target_state|
            journey = find_case_journey_for_state target_state.to_sym
            @number_to_create.times do |n|
              puts "creating case #{target_state} ##{n}"
              kase = create_case()
              run_transitions(kase, target_state, journey, n)
              cases << kase
            end
          end
        ensure
          unless @dry_run
            tp cases, [:id, :number, :current_state, :requires_clearance?]
          end
        end
      end

      private

      def parse_options(options)
        @end_states = []
        @number_to_create = options.fetch(:number, 1)
        @flag = if options.key?(:flag_for_disclosure)
                  options[:flag_for_disclosure] ? 'disclosure' : nil
                elsif options.key?(:flag_for_team)
                  options[:flag_for_team]
                else
                  nil
                end
        @clear_cases = options.fetch(:clear, false)
        @dry_run = options.fetch(:dry_run, false)
        @created_at = options[:created_at]
        if options[:received_date]
          @recieved_date = options[:received_date]
        elsif @created_at.present? &&
              DateTime.parse(@created_at) < DateTime.now
          @received_date = @created_at
        end
      end

      def parse_params(args)
        args.each { |arg| process_arg(arg) }

        if @invalid_params
          command.error 'Program terminating'
          exit 1
        elsif @end_states.empty?
          command.error 'No states provided, please see help for what states are available.'
          exit 1
        end
      end

      def process_arg(arg)
        if arg == 'all'
          @end_states += get_journey_for_flagged_state(@flag)
        elsif find_case_journey_for_state(arg.to_sym).any?
          @end_states << arg
        else
          command.error "Unrecognised parameter: #{arg}"
          command.error "Journeys checked:"
          journeys_to_check.each do |name, states|
            command.error "  #{name}: #{states.join(', ')}"
          end
          @invalid_params = true
        end
      end

      def create_case()
        kase = FactoryGirl.create(:case,
                                  name: Faker::Name.name,
                                  subject: Faker::Company.catch_phrase,
                                  message: Faker::Lorem.paragraph(10, true, 10),
                                  managing_team: CTS::dacu_team,
                                  received_date: @received_date,
                                  created_at: @created_at)
        flag_for_dacu_disclosure(kase) if @flag.present?
        kase
      end

      def run_transitions(kase, target_state, journey, n)
        journey.each do |state|
          begin
            if @dry_run
              puts "  transition to '#{state}'"
            else
              __send__("transition_to_#{state}", kase)
              kase.reload
            end
          rescue => exx
            command.error "Error occured on case #{target_state} id:#{n}: #{exx.message}"
            command.error ""
            command.error "Case unsuccessfully transitioned to #{state}:"
            command.error "---------------------------------------"
            command.error kase.ai
            raise
          end
        end
      end

      def flag_for_dacu_disclosure(*cases)
        cases.each do |kase|
          dts = DefaultTeamService.new(kase)
          result = CaseFlagForClearanceService.new(
            user: CTS::dacu_manager,
            kase: kase,
            team: dts.approving_team,
          ).call
          unless result == :ok
            raise "Could not flag case for clearance by DACU Disclosure, case id: #{kase.id}, user id: #{CTS::dacu_manager.id}, result: #{result}"
          end
        end
      end

      def transition_to_awaiting_responder(kase)
        kase.responding_team = responding_team
        kase.assign_responder(CTS::dacu_manager, responding_team)
      end

      def transition_to_drafting(kase)
        kase.responder_assignment.accept(responder)
      end

      def transition_to_accepted_by_dacu_disclosure(kase)
        assignment = kase.approver_assignments
                       .where(team: CTS::dacu_disclosure_team).first
        user = CTS::dacu_disclosure_approver
        service = CaseAcceptApproverAssignmentService.new(
          assignment: assignment,
          user: user
        )

        unless service.call
          raise "Could not accept approver assignment, case id: #{kase.id}, user id: #{user.id}, result: #{service.result}"
        end
      end

      def transition_to_taken_on_by_press_office(kase)
        call_case_flag_for_clearance_service(kase, CTS::press_officer, CTS::press_office_team)
      end

      def transition_to_taken_on_by_private_office(kase)
        call_case_flag_for_clearance_service(kase, CTS::private_officer, CTS::private_office_team)
      end

      def transition_to_awaiting_dispatch(kase)
        if kase.approver_assignments.for_user(CTS::dacu_disclosure_approver).any?
          call_case_approval_service(CTS::dacu_disclosure_approver, kase)
        else
          ResponseUploaderService
            .new(kase, responder, { uploaded_files: nil }, nil)
            .seed!('spec/fixtures/eon.pdf')
          kase.state_machine.add_responses!(responder,
                                            responding_team,
                                            kase.attachments)
        end
      end

      def transition_to_responded(kase)
        kase.respond(responder)
      end

      def transition_to_pending_dacu_disclosure_clearance(kase)
        rus = ResponseUploaderService.new(kase,
                                          responder,
                                          { uploaded_files: nil },
                                          nil)
        rus.seed!('spec/fixtures/eon.pdf')
        kase.state_machine.add_response_to_flagged_case!(responder,
                                                         responding_team,
                                                         kase.attachments)
      end

      def transition_to_pending_press_office_clearance(kase)
        if kase.approver_assignments.for_user(CTS::dacu_disclosure_approver).any?
          call_case_approval_service(CTS::dacu_disclosure_approver, kase)
        end
      end

      def transition_to_pending_private_office_clearance(kase)
        if kase.approver_assignments.for_user(CTS::press_officer).any?
          call_case_approval_service(CTS::press_officer, kase)
        end
      end

      def transition_to_closed(kase)
        kase.prepare_for_close
        kase.update(date_responded: Date.today, outcome_name: 'Granted in full')
        kase.close(CTS::dacu_manager)
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def journeys_to_check
        CASE_JOURNEYS.find_all do |name, _states|
          @flag.blank? ||
            (@flag == 'disclosure' && name == :flagged_for_dacu_disclosure) ||
            (@flag == 'press' && name == :flagged_for_press_office) ||
            (@flag == 'private' && name == :flagged_for_private_office)
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def find_case_journey_for_state(state)
        journeys_to_check.each do |_name, states|
          pos = states.find_index(state)
          return states.take(pos + 1) if pos
        end
        return []
      end

      def get_journey_for_flagged_state(flag)
        case flag
        when 'disclosure'
          CASE_JOURNEYS[:flagged_for_dacu_displosure]
        when 'press'
          CASE_JOURNEYS[:flagged_for_press_office]
        when 'private'
          CASE_JOURNEYS[:flagged_for_private_office]
        else
          CASE_JOURNEYS[:unflagged]
        end
      end

      def responder
        @responder ||= if !options.key?(:responder)
                         if responding_team.responders.empty?
                           raise "Responding team '#{responding_team.name}' has no responders."
                         else
                           responding_team.responders.first
                         end
                       else
                         CTS::find_user(options[:responder])
                       end
      end

      def responding_team
        @responding_team ||= if !options.key?(:responding_team)
                               if options.key?(:responder)
                                 responder.responding_teams.first
                               else
                                 CTS::hmcts_team
                               end
                             else
                               CTS::find_team(options[:responding_team])
                             end
      end

      def press_officer
        BusinessUnit.press_office.approvers.first
      end

      def call_case_approval_service(user, kase)
        result = CaseApprovalService
                   .new(user: user, kase: kase).call
        unless result == :ok
          raise "Could not approve case response , case id: #{kase.id}, user id: #{user.id}, result: #{result}"
        end
      end

      def call_case_flag_for_clearance_service(kase, user, team)
        service = CaseFlagForClearanceService.new user: user, kase: kase, team: team
        result = service.call
        unless result == :ok
          raise "Could not flag case for clearance, case id: #{kase.id}, user id: #{user.id}, result: #{result}"
        end
      end

    end
  end
end
