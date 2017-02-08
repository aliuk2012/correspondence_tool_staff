# == Schema Information
#
# Table name: case_attachments
#
#  id         :integer          not null, primary key
#  case_id    :integer
#  type       :enum
#  url        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'
require 'rspec/expectations'

RSpec::Matchers.define :allow_url_file_extension do |extension|
  match do
    subject.url = "https://s3.amazon.com/bucket/uploads/file.#{extension}"
    subject.type = 'response'
    subject.valid?
  end
end

RSpec.describe CaseAttachment, type: :model do
  describe 'type enum' do
    it { should have_enum(:type).with_values ['response'] }
  end

  describe 'file type validation' do
    it { should allow_url_file_extension('pdf')  }
    it { should allow_url_file_extension('doc')  }
    it { should allow_url_file_extension('docx') }
    it { should allow_url_file_extension('xls')  }
    it { should allow_url_file_extension('xlsx') }

    it { should_not allow_url_file_extension('exe') }
    it { should_not allow_url_file_extension('com') }
    it { should_not allow_url_file_extension('bat') }
  end
end
