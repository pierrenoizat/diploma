class ViewerValidator < ActiveModel::Validator
  
  def validate(record)
    
    deed = Deed.find_by_id(record.deed_id)
    if deed
      
      user = User.find_by_id(deed.user_id)
      if user
        if user.email == record.email
          record.errors[:base] << "Deed belongs to viewer: no need to add this viewer already authorized."
        end

        deed.viewers.each do |viewer|
          if viewer.email == record.email
            record.errors[:base] << "Viewer has been already authorized."
          end
        end
      end
      
    end
    
  end # of validate method
  
end


class Viewer < ActiveRecord::Base
  
  belongs_to :deed
  
  validates_with ViewerValidator
  
  validates :email, presence: true
  
  validates :email, format: { with: /\A([\w\.%\+\-]+)@([\w\-]+\.)+([\w]{2,})\z/i,
      message: "invalid email" }
  
end
