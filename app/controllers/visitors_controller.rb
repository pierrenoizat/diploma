class VisitorsController < ApplicationController
  
  def index
    Deed.all.each do |deed|
      if ((deed.access_key.blank? or deed.access_key.size != 20) and !deed.user_id.blank?)
        deed.update(access_key: SecureRandom.hex(10))
      end
    end
  end
  
end
