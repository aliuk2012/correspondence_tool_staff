# == Schema Information
#
# Table name: teams
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  email      :citext           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  type       :string
#  parent_id  :integer
#

class BusinessGroup < Team
  validates_absence_of :parent_id

  has_many :directorates, foreign_key: 'parent_id'
end