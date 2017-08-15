require 'rails_helper'

describe 'teams/show.html.slim', type: :view do

  let(:manager)   { create :manager }

  def login_as(user)
    allow(view).to receive(:current_user).and_return(user)
  end

  context 'showing a business group' do
    before(:all) do
      @hmpps      = create_business_group('HMPPS', 'Michael Spurr')
      @prisons    = create_directorate(@hmpps, 'Prisons', 'Phil Copple')
      @ops        = create_business_unit(@prisons, 'Operations', 'Jack Harris')
      @ypt        = create_business_unit(@prisons, 'Young People Team', 'Cathy Rbinson')
      @hr         = create_directorate(@hmpps, 'HR', 'Martin Beecroft')
      @hmpps_hr   = create_business_unit(@hr, 'HMPPS HR', 'Dave Mann')
    end

    after(:all) { DbHousekeeping.clean }


    it 'displays the directorates inside it' do
      login_as manager
      assign(:team, @hmpps)
      assign(:children, [ @prisons, @hr ] )

      render

      teams_show_page.load(rendered)

      expect(teams_show_page.heading)
        .to have_text 'You are viewing Business group HMPPS'

      expect(teams_show_page.heading.text)
        .to have_text 'You are viewing Business group HMPPS'
      bg = teams_show_page.row_for_directorate('Prisons')
      expect(bg.name.text).to eq 'View the details of Prisons'
      expect(bg.director.text).to eq 'Phil Copple'
      expect(bg.num_business_units.text).to eq '2'
      expect(bg.actions.text).to eq 'Edit'

      bg = teams_show_page.row_for_directorate('HR')
      expect(bg.name.text).to eq 'View the details of HR'
      expect(bg.director.text).to eq 'Martin Beecroft'
      expect(bg.num_business_units.text).to eq '1'
      expect(bg.actions.text).to eq 'Edit'
    end
  end

  context 'showing a business unit' do
    let(:bu)          { create :business_unit }
    let!(:responder1) { create :responder, responding_teams: [bu] }
    let!(:responder2) { create :responder, responding_teams: [bu] }

    before do
      login_as manager
      assign(:team, bu)
    end

    it 'displays the business unit name' do
      render
      teams_show_page.load(rendered)

      expect(teams_show_page.heading).to have_text "Business unit #{bu.name}"
    end

    it 'displays the deputy director' do
      render
      teams_show_page.load(rendered)

      expect(teams_show_page.deputy_director)
        .to have_text "Deputy director#{bu.team_lead.value}"
    end

    it 'displays the information officers' do
      render
      teams_show_page.load(rendered)

      user1 = teams_show_page.information_officers_list.first
      expect(user1.name.text).to  eq responder1.full_name
      expect(user1.email.text).to eq responder1.email
      user2 = teams_show_page.information_officers_list.second
      expect(user2.name.text).to  eq responder2.full_name
      expect(user2.email.text).to eq responder2.email
    end

    it 'displays a button to add new information officers' do
      render
      teams_show_page.load(rendered)

      expect(teams_show_page).to have_new_information_officer_button
      expect(teams_show_page.new_information_officer_button[:href])
        .to eq "/teams/#{bu.id}/users/new?role=responder"
    end
  end

  private

  def create_business_group(name, team_lead)
    create :business_group,
           name: name,
           lead: create(:team_lead, value: team_lead)
  end

  def create_directorate(bg, name, team_lead)
    create :directorate,
           name: name,
           business_group: bg,
           lead: create(:team_lead, value: team_lead)
  end

  def create_business_unit(directorate, name, team_lead)
    create :business_unit,
           name: name,
           directorate: directorate,
           lead: create(:team_lead, value: team_lead)
  end


  def add_team_lead(team, team_lead)
    TeamProperty.create!(team_id: team.id, key: 'lead', value: team_lead)
  end
end
