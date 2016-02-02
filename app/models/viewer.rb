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
      
  before_create :generate_access_key

  def to_param
    self.access_key
  end

  def generate_access_key
    self.access_key = [id.to_s, SecureRandom.hex(10)].join
  end
  
  def addition_email

     client = SendGrid::Client.new(api_key: Rails.application.secrets.sendgrid_api_key)
     
     mail = SendGrid::Mail.new do |m|
       m.to = self.email
       m.from = 'diploma.report'
       m.subject = 'Authorized viewer confirmation'
       m.text = "You are now authorized to share information about this deed, #{Deed.find_by_id(self.deed_id).name}. Please use this unique link: #{$ROOT_URL}/viewers/#{self.access_key}"
     end

     res = client.send(mail)
     puts res.code
     puts res.body
   end
  
end
