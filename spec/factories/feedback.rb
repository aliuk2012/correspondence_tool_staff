# == Schema Information
#
# Table name: feedback
#
#  id         :integer          not null, primary key
#  content    :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

FactoryGirl.define do
  factory :feedback do
    comment { Faker::Lorem.paragraph(1) }
    email {  Faker::Internet.email }
  end
end