# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

@issuers = UpdateMpkService.new.call
string = 'UPDATED MPKS: '
@issuers.each do |issuer|
  string = string + ', '
  string = string << issuer.mpk
end
puts string

$SCHOOLS.each do |school|
   unless Issuer.find_by_name(school)
     Issuer.create(name: school)
   end
 end

@deeds=Deed.all
@deeds.each do |deed|
     deed.tx_id = deed.tx_hash
     deed.save
 end