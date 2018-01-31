require 'rails_helper'

describe 'cases/edit.html.slim', type: :view do

  it 'displays the edit case page' do
    Timecop.freeze(Time.new(2016,8,13,12,15,45)) do

      kase = create :accepted_case, name: 'John Doe',
                                    email: 'jd@moj.com',
                                    requester_type: :journalist,
                                    subject: 'Ferrets',
                                    message: 'Can I keep a ferret in jail',
                                    received_date: Date.new(2016,8,13)

      assign(:correspondence_type, 'foi')
      assign(:case, kase)

      render

      cases_edit_page.load(rendered)

      page = cases_edit_page

      expect(page.page_heading.heading.text).to eq "Edit case details"
      expect(page.page_heading.sub_heading.text.strip).to eq kase.number

      expect(page.date_received_day.value).to eq '13'
      expect(page.date_received_month.value).to eq '8'
      expect(page.date_received_year.value).to eq '2016'

      expect(page.form['action']).to match(/^\/cases\/\d+$/)

      expect(page.subject.value).to eq 'Ferrets'
      expect(page.full_request.value).to eq 'Can I keep a ferret in jail'
      expect(page.full_name.value).to eq 'John Doe'
      expect(page.email.value).to eq 'jd@moj.com'
      expect(page).to have_address
      expect(page).to have_submit_button

      expect(page.submit_button.value).to eq "Submit"
    end


  end

end
