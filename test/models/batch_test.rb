require 'test_helper'

class BatchTest < ActiveSupport::TestCase
  
  test "should be findable by title" do
    batch = FactoryGirl.create(:batch)
    assert_equal batch, Batch.find_by_title("2008")
  end
  
  test "should get address from self.id and self.issuer.mpk" do
    @issuer = FactoryGirl.create(:issuer_with_batch)
    @batch = @issuer.batches.first
    assert_equal @batch.payment_address, @batch.address
  end
  
end
