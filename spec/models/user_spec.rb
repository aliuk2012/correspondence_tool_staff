# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  full_name              :string           not null
#

require 'rails_helper'

RSpec.describe User, type: :model do

  subject { create(:user) }

  it { should have_many(:assignments) }
  it { should have_many(:cases)       }
  it { should validate_presence_of(:full_name) }
  it { should have_many(:team_roles).class_name('TeamsUsersRole') }
  it { should have_many(:teams).through(:team_roles) }
end
