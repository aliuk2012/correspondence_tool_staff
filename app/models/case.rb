# == Schema Information
#
# Table name: cases
#
#  id                   :integer          not null, primary key
#  name                 :string
#  email                :string
#  message              :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  category_id          :integer
#  received_date        :date
#  postal_address       :string
#  subject              :string
#  properties           :jsonb
#  requester_type       :enum
#  number               :string           not null
#  date_responded       :date
#  outcome_id           :integer
#  refusal_reason_id    :integer
#  current_state        :string
#  last_transitioned_at :datetime
#

# Required in production with it's eager loading and cacheing of classes.
require 'case_state_machine'

class Case < ApplicationRecord
  include Statesman::Adapters::ActiveRecordQueries

  acts_as_gov_uk_date :received_date, :date_responded,
                      validate_if: :received_in_acceptable_range?

  scope :by_deadline, -> {order("(properties ->> 'external_deadline')::timestamp with time zone ASC, cases.id") }
  scope :most_recent_first, -> {reorder("(properties ->> 'external_deadline')::timestamp with time zone DESC, cases.id") }

  scope :opened, -> { where.not(current_state: 'closed')}
  scope :closed, -> { where(current_state: 'closed').order(last_transitioned_at: :desc) }

  scope :with_teams, -> (teams) do
    includes(:assignments)
      .where(assignments: { team: teams,
                            state: ['pending', 'accepted']})
  end
  scope :with_user, ->(*users) do
    includes(:assignments)
      .where(assignments: { user_id: users.map { |u| u.id },
                            state: ['pending', 'accepted']})
  end

  scope :accepted, -> { joins(:assignments).where.not(assignments: {user: nil} ) }
  scope :unaccepted, -> { joins(:assignments).where(assignments: {user: nil} ) }

  scope :waiting_to_be_accepted, ->(*teams) do
    includes(:assignments)
      .where(assignments: { team_id: teams.map { |t| t.id },
                            state: ['pending']})
  end

  scope :flagged_for_approval, ->(*teams) do
    joins(:assignments)
      .where(assignments: { team_id: teams.map(&:id), role: 'approving' })
  end

  scope :in_time, -> {
    where(
      "CASE WHEN current_state IN ('responded', 'closed') THEN date_responded <= (properties->>'external_deadline')::date ELSE ? <= properties->>'external_deadline' END",
      Date.today
    )
  }
  scope :late,    -> {
    where(
      "CASE WHEN current_state IN ('responded', 'closed') THEN date_responded > (properties->>'external_deadline')::date ELSE ? > properties->>'external_deadline' END",
      Date.today
    )
  }

  validates :current_state, presence: true, on: :update
  validates :received_date,:subject,:message, :name, :category, presence: true
  validates :email, presence: true, on: :create, if: -> { postal_address.blank? }
  validates :email, format: { with: /\A.+@.+\z/ }, if: -> { email.present? }
  validates :postal_address, presence: true, on: :create, if: -> { email.blank? }
  validates :subject, length: { maximum: 80 }
  validates :requester_type, presence: true

  validates_with ::ClosedCaseValidator

  serialize :exemption_ids, Array

  attr_accessor :flag_for_disclosure_specialists

  enum requester_type: {
      academic_business_charity: 'academic_business_charity',
      journalist: 'journalist',
      member_of_the_public: 'member_of_the_public',
      offender: 'offender',
      solicitor: 'solicitor',
      staff_judiciary: 'staff_judiciary',
      what_do_they_know: 'what_do_they_know'
    }

  jsonb_accessor :properties,
    escalation_deadline: :date,
    internal_deadline: :date,
    external_deadline: :date

  belongs_to :category, required: true

  has_many :assignments, dependent: :destroy
  has_one :managing_assignment,
          -> { managing },
          class_name: 'Assignment'
  has_one :managing_team,
          through: :managing_assignment,
          source: :team
  has_one :responder_assignment,
          -> { responding },
          class_name: 'Assignment'
  has_one :responder,
          through: :responder_assignment,
          source: :user
  has_one :responding_team,
          -> { where("state != 'rejected'") },
          through: :responder_assignment,
          source: :team
  has_many :approver_assignments,
          -> { approving },
          class_name: 'Assignment'
  has_many :approvers,
           through: :approver_assignments,
           source: :user
  has_many :approving_teams,
           -> { where("state != 'rejected'") },
           through: :approver_assignments,
           source: :team
  has_many :approving_team_users,
           through: :approving_teams,
           source: :users

  has_many :transitions, class_name: 'CaseTransition', autosave: false, dependent: :destroy
  has_many :responded_transitions, -> { responded }, class_name: 'CaseTransition'
  has_many :responder_history, through: :responded_transitions, source: :user

  has_many :attachments, -> { order(id: :desc) }, class_name: 'CaseAttachment', dependent: :destroy
  belongs_to :outcome, class_name: 'CaseClosure::Outcome'
  belongs_to :refusal_reason, class_name: 'CaseClosure::RefusalReason'
  has_and_belongs_to_many :exemptions, class_name: 'CaseClosure::Exemption', join_table: 'cases_exemptions'

  before_create :set_initial_state,
                :set_number,
                :set_managing_team,
                :set_deadlines
  before_save :prevent_number_change


  delegate :available_events, to: :state_machine

  CaseStateMachine.states.each do |state|
    define_method("#{state}?") { current_state == state }
  end

  include CaseStates

  def self.search(term)
    where('lower(name) LIKE ?', "%#{term.downcase}%")
  end

  # Commented out as this is not being used and we don't know how to re-write
  # this yet, we can wait until we actually need this method, and if we never
  # do we should just delete it.
  #
  # def awaiting_approver?
  #   self.approver_assignments.any? &:pending?
  # end

  def prevent_number_change
    raise StandardError.new('number is immutable') if number_changed?
  end

  def triggerable?
    !requires_clearance?
  end

  def under_review?
    triggerable? && within_escalation_deadline?
  end

  def within_escalation_deadline?
    escalation_deadline.future? || escalation_deadline.today?
  end

  def within_external_deadline?
    date_responded <= external_deadline
  end

  def received_in_acceptable_range?
    if received_date.present? && self.received_date > Date.today
      errors.add(
          :received_date,
          I18n.t('activerecord.errors.models.case.attributes.received_date.not_in_future')
      )
      true
    elsif received_date.present? && self.received_date < Date.today - 60.days
      errors.add(
        :received_date,
        I18n.t('activerecord.errors.models.case.attributes.received_date.past')
      )
      true
    else
      false
    end
  end

  def attachments_dir(attachment_type)
    "#{id}/#{attachment_type}"
  end

  def who_its_with
    if responding_team.present?
      responding_team.name
    else
      managing_team.name
    end
  end

  def outcome_name
    outcome&.name
  end

  def outcome_name=(name)
    self.outcome = CaseClosure::Outcome.by_name(name)
  end

  def refusal_reason_name
    refusal_reason&.name
  end

  def refusal_reason_name=(name)
    self.refusal_reason = CaseClosure::RefusalReason.by_name(name)
  end

  # returns a hash which can be used by for populating checkboxes
  # e.g. {"10"=>"1", "11"=>"1", "12"=>"0", "13"=>"0", "14"=>"1"}
  def exemption_ids
    exemption_hash = {}
    exemptions.map{ |ex| exemption_hash[ex.id.to_s] = '1' }
    exemption_hash
  end

  # expects a hash of ids and values 1 or zero
  # e.g. {"10"=>"1", "11"=>"1", "12"=>"0", "13"=>"0", "14"=>"1"}
  def exemption_ids=(param_hash)
    exemption_ids = param_hash.select { |_exemption_id, val| val == '1' }.keys
    self.exemptions = CaseClosure::Exemption.find(exemption_ids)
  end

  def prepare_for_close
    @preparing_for_close = true
  end

  def prepared_for_close?
    @preparing_for_close == true
  end

  def requires_exemption?
    refusal_reason.present? && refusal_reason.requires_exemption?
  end

  def has_ncnd_exemption?
    exemptions.select{ |ex| ex.ncnd? }.any?
  end

  def requires_clearance?
    approver_assignments.any? && approver_assignments.unapproved.any?
  end

  def does_not_require_clearance?
    !requires_clearance?
  end

  def with_teams?(teams)
    assignments.with_teams(teams).any?
  end

  private

  def set_initial_state
    self.current_state = 'unassigned'
    self.last_transitioned_at = Time.now
  end

  def set_deadlines
    self.escalation_deadline = DeadlineCalculator.escalation_deadline(self)
    self.internal_deadline = DeadlineCalculator.internal_deadline(self)
    self.external_deadline = DeadlineCalculator.external_deadline(self)
  end

  def set_managing_team
    # For now, we just automatically assign cases to DACU.
    self.managing_team =
      Team.managing.find_by!(name: Settings.foi_cases.default_managing_team)
    self.managing_assignment.state = 'accepted'
  end

  def set_number
    self.number = next_number
  end

  def next_number
    "%s%03d" % [
      received_date.strftime("%y%m%d"),
      CaseNumberCounter.next_for_date(received_date)
    ]
  end
end
