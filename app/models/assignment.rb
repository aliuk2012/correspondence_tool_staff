# == Schema Information
#
# Table name: assignments
#
#  id              :integer          not null, primary key
#  assignment_type :enum
#  state           :enum             default("pending")
#  case_id         :integer
#  assignee_id     :integer
#  assigner_id     :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Assignment < ApplicationRecord

  validates :assignment_type, :state, :case, :assigner, :assignee,
    presence: true

  enum state: {
    pending: 'pending', rejected: 'rejected', accepted: 'accepted'
  }

  enum assignment_type: {
    caseworker: 'caseworker', drafter: 'drafter'
  }

  belongs_to :case
  belongs_to :assigner, class_name: 'User'
  belongs_to :assignee, class_name: 'User'

  after_create :update_case

  private

  def update_case
    self.case.update(state: 'awaiting_drafter')
  end

end
