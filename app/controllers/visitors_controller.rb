class VisitorsController < ApplicationController
  
  def index
    Deed.all.each do |deed|
      if deed.access_key.blank? and !deed.user_id.blank?
        deed.update(access_key: [deed.upload, SecureRandom.hex(10)].join.truncate(20))
      end
    end
  end
  
end
