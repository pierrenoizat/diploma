require 'test_helper'

class IssuerTest < ActiveSupport::TestCase
  test "should be findable by name" do
    issuer= FactoryGirl.create(:issuer)
    assert_equal issuer, Issuer.find_by_name("MySchool")
  end
  
  test "should get address from self.id and self.mpk" do
    @issuer = FactoryGirl.create(:issuer)
    assert_equal @issuer.payment_address, '1Ft77yhYz8ASd7Fgu42yak3jSiLRwD4nu5'
  end
end
