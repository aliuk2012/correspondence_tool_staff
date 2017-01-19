require 'rails_helper'

RSpec.describe CaseStateMachine, type: :model do
  let(:kase) { create :case }
  let(:state_machine) do
    CaseStateMachine.new(
      kase,
      transition_class: CaseTransition,
      association_name: :transitions
    )
  end
  let(:assigner) { create :user, roles: ['assigner'] }
  let(:drafter)  { create :user, roles: ['drafter'] }

  it 'sets the initial state to "unassigned"' do
    expect(kase.current_state).to eq 'unassigned'
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

  describe '#assign_responder!' do
    before do
      state_machine.assign_responder!(assigner.id, drafter.id)
    end

    it 'triggers an assign_responder event' do
      expect(kase.current_state).to eq 'awaiting_responder'
    end

    describe 'transition' do
      subject { kase.transitions.last }

      it { should have_attributes(event:       'assign_responder',
                                  assignee_id: drafter.id,
                                  user_id:     assigner.id) }
    end
  end

  describe '#assign_responder' do
    it_behaves_like 'a case state machine event' do
      let(:event_name) { :assign_responder }
      let(:args) { [drafter.id, assigner.id] }
    end
  end

  describe '#reject_responder_assignment!' do
    let(:message) { |example| "test #{example.description}" }

    before do
      state_machine.assign_responder!(assigner.id, drafter.id)
      state_machine.reject_responder_assignment!(drafter.id, message)
    end

    it 'triggers a reject_responder_assignment event' do
      expect(kase.current_state).to eq 'unassigned'
    end

    it 'triggers the correct event transition' do
      allow(state_machine).to receive(:trigger!)
      state_machine.reject_responder_assignment!(drafter.id, message)
      expect(state_machine).to have_received(:trigger!).with(
                                 :reject_responder_assignment,
                                 assignee_id: drafter.id,
                                 user_id:     drafter.id,
                                 message:     message,
                                 event:       :reject_responder_assignment
                               )
    end
  end

  describe '#reject_responder_assignment' do
    before do
      state_machine.assign_responder!(assigner.id, drafter.id)
    end

    it_behaves_like 'a case state machine event' do
      let(:event_name) { :reject_responder_assignment }
      let(:message) { "#{event_name} test" }
      let(:args) { [drafter.id, message] }
    end
  end

  describe '#accept_responder_assignment!' do
    before do
      state_machine.assign_responder!(assigner.id, drafter.id)
      state_machine.accept_responder_assignment!(drafter.id)
    end

    it 'triggers a accept_responder_assignment event' do
      expect(kase.current_state).to eq 'drafting'
    end

    it 'triggers the correct event transition' do
      allow(state_machine).to receive(:trigger!)
      state_machine.accept_responder_assignment!(drafter.id)
      expect(state_machine).to have_received(:trigger!).with(
                                 :accept_responder_assignment,
                                 assignee_id: drafter.id,
                                 user_id:     drafter.id,
                                 event:       :accept_responder_assignment
                               )
    end
  end

  describe '#accept_responder_assignment' do
    before do
      state_machine.assign_responder!(assigner.id, drafter.id)
    end

    it_behaves_like 'a case state machine event' do
      let(:event_name) { :accept_responder_assignment }
      let(:args) { [drafter.id] }
    end
  end

end
