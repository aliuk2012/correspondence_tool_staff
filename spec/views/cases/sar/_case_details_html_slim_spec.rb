require 'rails_helper'

describe 'cases/sar/case_details.html.slim', type: :view do
  let(:unassigned_case)         { (create :sar_case).decorate }
  let(:accepted_case)           { (create :accepted_sar).decorate }
  let(:bmt_manager)             { create :disclosure_bmt_user }


  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
    super(user)
  end


  before(:each) { login_as bmt_manager }



  describe 'basic_details' do
    it 'displays the initial case details' do
      render partial: 'cases/sar/case_details.html.slim',
             locals:{ case_details: unassigned_case}

      partial = case_details_section(rendered).sar_basic_details
      expect(partial.case_type).to have_no_sar_trigger
      expect(partial.case_type.data.text).to eq "SAR  "
      expect(partial.date_received.data.text)
          .to eq unassigned_case.received_date.strftime(Settings.default_date_format)

    end

    it 'does not display the email address if one is not provided' do
      unassigned_case.email = nil
      unassigned_case.postal_address = "1 High Street\nAnytown\nAT1 1AA"
      unassigned_case.reply_method = 'send_by_post'

      render partial: 'cases/sar/case_details.html.slim',
             locals:{ case_details: unassigned_case}

      partial = case_details_section(rendered).sar_basic_details

      expect(partial).to have_response_address
      expect(partial.response_address.data.text).to eq "1 High Street\nAnytown\nAT1 1AA"
    end

    it 'does not display the postal address if one is not provided' do
      unassigned_case.postal_address = nil
      unassigned_case.email = 'john.doe@moj.com'

      render partial: 'cases/sar/case_details.html.slim',
             locals:{ case_details: unassigned_case}

      partial = case_details_section(rendered).sar_basic_details

      expect(partial).to have_response_address
      expect(partial.response_address.data.text).to eq 'john.doe@moj.com'
    end
  end

  describe 'responders details' do
    it 'displays the responders team name' do
      render partial: 'cases/sar/case_details.html.slim',
             locals:{ case_details: accepted_case}

      partial = case_details_section(rendered).responders_details

      expect(partial).to be_all_there
      expect(partial.team.data.text).to eq accepted_case.responding_team.name
      expect(partial.name.data.text).to eq accepted_case.responder.full_name
    end
  end



end