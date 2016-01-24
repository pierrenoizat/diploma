class User < ActiveRecord::Base
  enum category: [:student, :vip, :visitor, :customer]
  has_many :deeds

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      if auth['info']
         user.name = auth['info']['name'] || ""
         user.email = auth['info']['email'] || ""
      end
    end
  end
  
  def viewer?(id)
    
    # check whether user is an authorized viewer for deed with id id
    authorized = false
    diploma = Deed.find_by_id(id)
    if diploma
      diploma.viewers.each do |viewer|
        if viewer.email == self.email
          authorized = true
        end
      end
    end
    authorized
  end

end
