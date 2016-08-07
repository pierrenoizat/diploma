require 'test_helper'

class BatchesControllerTest < ActionController::TestCase
  test "index action" do
    # must be signed in as admin!
    FactoryGirl.create(:batches)
    get :index
    assert_select "div.row", :count => (assigns(:batches).size + 1)
    assert_not_nil assigns(:batches)
  end
end
