require File.join(Rails.root, 'db', 'seeders', 'correspondence_type_seeder')
require File.join(Rails.root, 'db', 'seeders', 'case_closure_metadata_seeder')
require File.join(Rails.root, 'db', 'seeders', 'report_type_seeder')
require File.join(Rails.root, 'db', 'seeders', 'user_seeder')


# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)


CorrespondenceTypeSeeder.new.seed!
ReportTypeSeeder.new.seed!(verbose: true)
CaseClosure::MetadataSeeder.seed!(verbose: true)

