# == Schema Information
#
# Table name: case_attachments
#
#  id         :integer          not null, primary key
#  case_id    :integer
#  type       :enum
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  key        :string
#

FactoryGirl.define do
  factory :case_attachment do
    association :case, strategy: :build
    # TODO: The random hex number below isn't strictly true, we should have a
    #       hash of the case's ID ... except the default factory here doesn't
    #       have a case with an ID since we use strategy: :build. The reason
    #       for that is that we were getting errors in tests when using the
    #       default strategy of :create, so we need to fix that to fix the hex
    #       number we generate here.
    key { "#{SecureRandom.hex(16)}/responses/#{Faker::Internet.slug}.pdf" }
  end

  factory :correspondence_response, parent: :case_attachment do
    type 'response'
  end
  factory :case_response, parent: :correspondence_response do
    # Whatever was I thinking calling it :correspondence_response? Why didn't
    # you stop me Eddie?!?!
  end
end