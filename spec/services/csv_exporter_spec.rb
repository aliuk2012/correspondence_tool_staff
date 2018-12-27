require 'rails_helper'

describe CSVExporter do

  # let(:responding_team)   { create :responding_team, name: 'Transport for London' }
  # let(:responder)         { create :responder, full_name: 'Joe Smith', responding_teams: [ responding_team] }
  let(:foi_case)          { create :closed_case, :fully_refused_exempt_s40,
                                   name: 'FOI Case name',
                                   email: 'dave@moj.com',
                                   message: 'foi message',
                                   postal_address: nil }
  let(:sar_case)          { create :closed_sar,
                                   name: 'SAR case name',
                                   postal_address: "2 High Street\nAnytown\nAY2 4FF",
                                   subject: 'Full details required',
                                   email: 'theresa@moj.com',
                                   message: 'my SAR message',
                                   subject_full_name: 'Theresa Cant' }

  context 'FOI' do
    it 'returns an array of fields' do
      Timecop.freeze Time.local(2018, 10, 1, 13, 21, 33) do
        csv = CSVExporter.new(foi_case).to_csv
        expect(csv).to eq [
                             '180830001',
                             'FOI',
                             'closed',
                             'FOI Responding Team',
                             'foi responding user',
                             '2018-08-30',
                             '2018-09-13',
                             '2018-09-27',
                             '2018-09-25',
                             '2018-09-25',
                             'standard',
                             'FOI Case name',
                             'member_of_the_public',
                             'foi message',
                             'Yes',
                             'Refused fully',
                             nil,
                             's40',
                             nil,
                             'dave@moj.com',
                             nil,
                             nil,
                             nil,
                             nil,
                             nil
                         ]
      end
    end
  end

  context 'SAR' do
    it 'returns sar fiels' do
      Timecop.freeze Time.local(2018, 10, 1, 13, 21, 33) do
        csv = CSVExporter.new(sar_case).to_csv
        expect(csv).to eq [
                              '180830001',
                              'SAR',
                              'closed',
                              'SAR Responding Team',
                              'sar responding user',
                              '2018-08-30',
                              '2018-09-09',
                              '2018-09-29',
                              '2018-09-25',
                              nil,
                              'standard',
                              'SAR case name',
                              nil,
                              'my SAR message',
                              nil,
                              nil,
                              nil,
                              '',
                              "2 High Street\nAnytown\nAY2 4FF",
                              'theresa@moj.com',
                              nil,
                              false,
                              'send_by_email',
                              'offender',
                              'Theresa Cant'
                          ]
      end

    end
  end
end
