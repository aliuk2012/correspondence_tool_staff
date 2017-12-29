# == Schema Information
#
# Table name: report_types
#
#  id            :integer          not null, primary key
#  abbr          :string           not null
#  full_name     :string           not null
#  class_name    :string           not null
#  custom_report :boolean          default(FALSE)
#  seq_id        :integer          not null
#

FactoryGirl.define do
  factory :report_type do
    sequence(:abbr) { |n| "R#{n}" }
    sequence(:full_name) { |n| "Report #{n}" }
    class_name { "#{full_name.classify}" }
    custom_report false
    sequence(:seq_id) { |n| n + 100}

    trait :r003 do
      abbr          'R003'
      full_name     'Business unit report'
      class_name    'Stats::R003BusinessUnitPerformanceReport'
      custom_report true
      seq_id        200
    end

    trait :r004 do
      abbr          'R004'
      full_name     'Cabinet Office report'
      class_name    'Stats::R004CabinetOfficeReport'
      custom_report false
      seq_id        300
    end
  end

  factory :r003_report_type, parent: :report_type do
    abbr 'R003'
    full_name 'Business unit report'
    class_name 'Stats::R003BusinessUnitPerformanceReport'
    custom_report true
    seq_id 200
  end

  factory :r004_report_type, parent: :report_type do
    abbr 'R004'
    full_name 'Cabinet Office report'
    class_name 'Stats::R004CabinetOfficeReport'
    custom_report true
    seq_id 300
  end
end