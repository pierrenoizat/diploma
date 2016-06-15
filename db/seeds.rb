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

Deed.all.each do |deed|
     deed.tx_id = deed.tx_hash
     deed.save
 end

@users = User.all
@users.each do |user|
 @issuer_exist = false
 @issuers=Issuer.all
 @issuers.each do |issuer|
   if (issuer.name == user.email)
     @issuer_exist = true
     user.issuer_id = issuer.id
     user.save
   end
 end
 puts user.issuer_id
 puts @issuer_exist
 unless @issuer_exist
   @issuer = Issuer.create(:name => user.email, :mpk => Rails.application.secrets.mpk)
   puts @issuer.name
   puts @issuer.id
   if user.issuer_id.blank?
     user.issuer_id = @issuer.id
     user.save
   end
 end
 end