class Issuer < ActiveRecord::Base
  enum category: [:school, :individual]
  has_many :deeds
  has_many :users
  SCHOOLS = ["TEST SCHOOL", "ESILV", "CDI", "TEST"]
  # validates :name, :inclusion => SCHOOLS # not anymore, since email address is a user default issuer name
  
  validates :mpk, presence: true
  validates :name, presence: true
  validates :name, uniqueness: true
  
end
