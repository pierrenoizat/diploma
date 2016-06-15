class User < ActiveRecord::Base
  enum category: [:student, :vip, :visitor, :customer, :issuer, :admin]
  has_many :deeds
  belongs_to :issuer
  
  validates :email, presence: true
  validates :email, uniqueness: true
  
  before_create :set_credit

  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      if auth['info']
         user.name = auth['info']['name'] || ""
         user.email = auth['info']['email'] || ""
      end
      @issuer = Issuer.create(:category => :individual, :name => user.email, :mpk => Rails.application.secrets.mpk)
      user.issuer_id = @issuer.id
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
  
  
  def admin?
    self.uid == Rails.application.secrets.admin_uid
  end
  
  private
  
  def set_credit
    self.credit = 1
  end

end
