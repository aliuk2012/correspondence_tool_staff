# == Schema Information
#
# Table name: case_transitions
#
#  id          :integer          not null, primary key
#  event       :string
#  to_state    :string           not null
#  metadata    :jsonb
#  sort_key    :integer          not null
#  case_id     :integer          not null
#  most_recent :boolean          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer
#

class CaseTransition < ActiveRecord::Base
  belongs_to :case, inverse_of: :transitions

  after_destroy :update_most_recent, if: :most_recent?

  validates :message, presence: true, if: -> { event == 'add_message_to_case' }

  jsonb_accessor :metadata,
    user_id:            :integer,
    original_user_id:   :integer,
    responding_team_id: :integer,
    managing_team_id:   :integer,
    approving_team_id:  :integer,
    messaging_team_id:  :integer,
    message:            :text,
    target_user_id:     :integer,
    target_team_id:     :integer,
    acting_user_id:     :integer,
    acting_team_id:     :integer,
    filenames:          [:string, array: true, default: []]

  belongs_to :user
  belongs_to :responding_team, class_name: Team
  belongs_to :managing_team, class_name: Team
  belongs_to :approving_team, class_name: Team

  scope :accepted,  -> { where to_state: 'drafting'  }
  scope :drafting,  -> { where to_state: 'drafting'  }
  scope :messages,  -> { where event: 'add_message_to_case' }
  scope :responded, -> { where event: 'respond' }


  def record_state_change(kase)
    kase.update!(current_state: self.to_state, last_transitioned_at: self.created_at)
  end

  private

  def update_most_recent
    last_transition = self.case.transitions.order(:sort_key).last
    return unless last_transition.present?
    last_transition.update_column(:most_recent, true)
  end
end
