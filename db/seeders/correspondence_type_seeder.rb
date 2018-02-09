class CorrespondenceTypeSeeder

  def seed!
    puts "----Seeding Correspondence Types----"
    CorrespondenceType.find_or_create_by! name: 'Freedom of information request',
                                          abbreviation: 'FOI',
                                          escalation_time_limit: 3,
                                          internal_time_limit: 10,
                                          external_time_limit: 20
    CorrespondenceType.find_or_create_by! name: 'General enquiry',
                                          abbreviation: 'GQ',
                                          escalation_time_limit: 0,
                                          internal_time_limit: 10,
                                          external_time_limit: 15
    CorrespondenceType.find_or_create_by! name: 'Subject Access Request',
                                          abbreviation: 'SAR',
                                          escalation_time_limit: 0,
                                          internal_time_limit: 10,
                                          external_time_limit: 15
  end
end
