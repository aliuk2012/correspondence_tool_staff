require 'rails_helper'

RSpec::Matchers.define :trigger_the_event do |event|
  match do |code|
    allow(@state_machine).to receive(:trigger!)
    code.call
    expect(@state_machine)
      .to have_received(:trigger!).with(
            event,
            @parameters.merge({ event: event }),
          )
  end

  chain :on_state_machine do |state_machine|
    @state_machine = state_machine
  end

  chain :with_parameters do |params|
    @parameters = params
  end

  supports_block_expectations
end


RSpec::Matchers.define :have_event do |event|
  match do |state_machine|
    expect(state_machine.class.events).to have_key event
    @from_state ||= state_machine.current_state
    expect(state_machine.class.events[event][@from_state])
      .to include @to_state.to_s
  end

  chain :transition_from do |from_state|
    @from_state = from_state
  end

  chain :transition_to do |to_state|
    @to_state = to_state
  end
end


RSpec::Matchers.define :use_the_unsafe_trigger do |trigger|
  match do |code|
    allow(@state_machine).to receive(trigger)
    code.call
    expect(@state_machine).to have_received(trigger).with(@args)

    allow(@state_machine).to receive(trigger).
                               and_raise(Statesman::TransitionFailedError)
    expect(code.call).to be false

    allow(@state_machine).to receive(trigger).
                               and_raise(Statesman::GuardFailedError)
    expect(code.call).to be false

    allow(@state_machine).to receive(trigger).
                              and_raise(Exception)
    expect { code.call } .to raise_exception(Exception)
  end

  chain :on_state_machine do |state_machine|
    @state_machine = state_machine
  end

  chain :with_args do |args|
    @args = args
  end

  supports_block_expectations
end


RSpec.describe CaseStateMachine, type: :model do
  let(:kase)            { create :case }
  let(:state_machine) do
    CaseStateMachine.new(
      kase,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end
  let(:managing_team)   { create :managing_team }
  let(:manager)         { managing_team.managers.first }
  let(:responding_team) { create :responding_team }
  let(:responder)       { responding_team.responders.first }
  let(:assigned_case)   { create :assigned_case,
                                 responding_team: responding_team }

  context 'after transition' do
    let(:t1) { Time.new(2017, 4, 25, 10, 13, 55) }
    let(:t2) { Time.new(2017, 4, 27, 23, 14, 2) }
    it 'stores current state and time of transition on the case record' do
      Timecop.freeze(t1) do
        kase = create :case, received_date: Time.now - 1.day
        expect(kase.current_state).to eq 'unassigned'
        expect(kase.last_transitioned_at).to eq t1
      end
      Timecop.freeze(t2) do
        kase.assign_responder(manager, responding_team)
      end
      expect(kase.current_state).to eq 'awaiting_responder'
      expect(kase.last_transitioned_at).to eq t2
    end
  end

  shared_examples 'a case state machine event' do
    let(:event_name!) { "#{event_name}!".to_sym }
    let(:exception) { Class.new Exception }

    it 'uses the unsafe version of event' do
      allow(state_machine).to receive(event_name!)
      state_machine.send(event_name, *args)
      expect(state_machine).to have_received(event_name!).with(*args)
    end

    it 'protects against TransitionFailedError exceptions' do
      allow(state_machine).to receive(event_name!).
                                and_raise(Statesman::TransitionFailedError)
      result = state_machine.send(event_name, *args)
      expect(result).to be_falsey
    end

    it 'protects against TransitionFailedError exceptions' do
      allow(state_machine).to receive(event_name!).
                                and_raise(Statesman::GuardFailedError)
      result = state_machine.send(event_name, *args)
      expect(result).to be_falsey
    end

    it 'allows other exceptions through' do
      allow(state_machine).to receive(event_name!).
                                and_raise(exception)
      expect do
        state_machine.send(event_name, *args)
      end.to raise_exception(exception)
    end
  end

  context 'new case' do
    describe '#assign_responder!' do
      before do
        state_machine.assign_responder!(manager, managing_team, responding_team)
      end

      it 'triggers an assign_responder event' do
        expect(kase.current_state).to eq 'awaiting_responder'
      end

      describe 'transition' do
        subject { kase.transitions.last }

        it { should have_attributes(
                      event:           'assign_responder',
                      managing_team:   managing_team,
                      responding_team: responding_team,
                      user:            manager,
                    ) }
      end
    end

    describe '#assign_responder' do
      it_behaves_like 'a case state machine event' do
        let(:event_name) { :assign_responder }
        let(:args) { [manager, managing_team, responding_team] }
      end
    end
  end

  context 'assigned case awaiting responder' do
    let(:state_machine) { assigned_case.state_machine }

    describe 'event flag_for_clearance' do
      subject { assigned_case.state_machine }

      it { should have_event(:flag_for_clearance)
                    .transition_to(:awaiting_responder) }
    end

    describe 'trigger flag_for_clearance!' do
      it 'triggers a flag_for_clearance event' do
        expect { assigned_case.state_machine.flag_for_clearance!(manager) }
          .to trigger_the_event(:flag_for_clearance)
                .on_state_machine(assigned_case.state_machine)
                .with_parameters user_id: manager.id
      end
    end

    describe 'trigger flag_for_clearance' do
      it 'uses the unsafe trigger, making it safe' do
        expect { assigned_case.state_machine.flag_for_clearance(manager) }
          .to use_the_unsafe_trigger(:flag_for_clearance!)
                .on_state_machine(assigned_case.state_machine)
                .with_args(manager)
      end
    end

    describe '#accept_responder_assignment!' do
      it 'triggers an accept_responder_assignment event' do
        state_machine.accept_responder_assignment!(responder, responding_team)
        expect(assigned_case.current_state).to eq 'drafting'
      end

      it 'triggers the correct event transition' do
        allow(state_machine).to receive(:trigger!)
        state_machine.accept_responder_assignment!(responder, responding_team)
        expect(state_machine)
          .to have_received(:trigger!).with(
                :accept_responder_assignment,
                responding_team_id: responding_team.id,
                user_id:            responder.id,
                event:              :accept_responder_assignment,
              )
      end
    end

    describe '#accept_responder_assignment' do
      it_behaves_like 'a case state machine event' do
        let(:event_name) { :accept_responder_assignment }
        let(:args) { [responder, responding_team] }
      end
    end

    let(:message) { |example| "test #{example.description}" }

    describe '#reject_responder_assignment!' do
      it 'triggers a reject_responder_assignment event' do
        state_machine.reject_responder_assignment! responder,
                                                   responding_team,
                                                   message
        expect(assigned_case.current_state).to eq 'unassigned'
      end

      it 'triggers the correct event transition' do
        allow(state_machine).to receive(:trigger!)
        state_machine.reject_responder_assignment! responder,
                                                   responding_team,
                                                   message
        expect(state_machine).to have_received(:trigger!).with(
                                   :reject_responder_assignment,
                                   responding_team_id: responding_team.id,
                                   user_id:            responder.id,
                                   message:            message,
                                   event:              :reject_responder_assignment
                                 )
      end
    end

    describe '#reject_responder_assignment' do
      it_behaves_like 'a case state machine event' do
        let(:event_name) { :reject_responder_assignment }
        let(:message) { "#{event_name} test" }
        let(:args) { [responder, responding_team, message] }
      end
    end
  end

  context 'accepted case being drafted' do
    let(:kase)            { create :accepted_case }
    let(:manager)         { create :manager }
    let(:responder)       { kase.responder }
    let(:responding_team) { kase.responding_team }

    describe '#add_responses!' do
      it 'triggers a add_responses event, but does not change current_state' do
        state_machine.add_responses! responder,
                                     responding_team,
                                     ['file1.pdf', 'file2.pdf']
        expect(kase.current_state).to eq 'awaiting_dispatch'
      end

      it 'triggers the correct event transition' do
        allow(state_machine).to receive(:trigger!)
        state_machine.add_responses! responder,
                                     responding_team,
                                     ['file1.pdf', 'file2.pdf']
        expect(state_machine).to have_received(:trigger!).with(
                                   :add_responses,
                                   responding_team_id: responding_team.id,
                                   user_id:            responder.id,
                                   filenames:          ['file1.pdf', 'file2.pdf'],
                                   event:              :add_responses
                                 )
      end
    end

    describe '#add_responses' do
      it_behaves_like 'a case state machine event' do
        let(:event_name) { :add_responses }
        let(:args) { [responder, responding_team, ['file1.pdf', 'file2.pdf']] }
      end
    end
  end

  context 'case with a response' do
    let(:kase) { create :case_with_response,
                        responding_team: responding_team,
                        responder: responder }

    describe '#respond!' do
      it 'triggers a respond event' do
        state_machine.respond!(responder, responding_team)
        expect(kase.current_state).to eq 'responded'
      end

      it 'triggers the correct event transition' do
        allow(state_machine).to receive(:trigger!)
        state_machine.respond!(responder, responding_team)
        expect(state_machine).to have_received(:trigger!).with(
                                   :respond,
                                   responding_team_id: responding_team.id,
                                   user_id:            responder.id,
                                   event:              :respond
                                 )
      end
    end

    describe '#respond' do
      let(:kase)          { create(:case_with_response)  }
      let(:state_machine) { kase.state_machine                    }

      it_behaves_like 'a case state machine event' do
        let(:event_name) { :respond     }

        let(:args)       { [responder, responding_team] }
      end
    end
  end

  context 'case that has been responded to' do
    let(:kase) { create(:responded_case, outcome: create(:outcome)) }

    describe '#close!' do
      it 'triggers a close event' do
        state_machine.close!(manager, managing_team)
        expect(kase.current_state).to eq 'closed'
      end

      it 'triggers the correct event transition' do
        allow(state_machine).to receive(:trigger!)
        state_machine.close!(manager, managing_team)
        expect(state_machine).to have_received(:trigger!).with(
                                   :close,
                                   user_id:          manager.id,
                                   managing_team_id: managing_team.id,
                                   event:            :close
                                 )
      end
    end

    describe '#close' do
      it_behaves_like 'a case state machine event' do
        let(:event_name) { :close      }
        let(:args)       { [manager, managing_team] }
      end
    end
  end

  describe '.event_name' do
    context 'valid state machine event' do
      it 'returns human readable format' do
        expect(CaseStateMachine.event_name(:accept_responder_assignment)).to eq 'Accept responder assignment'
      end
    end

    context 'invalid state machine event' do
      it 'returns nil' do
        expect(CaseStateMachine.event_name(:trigger_article_50)).to be_nil
      end
    end
  end
end
