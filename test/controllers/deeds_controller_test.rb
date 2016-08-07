require 'test_helper'

class DeedsControllerTest < ActionController::TestCase
  setup do
    @issuer = FactoryGirl.create(:issuer_with_batch)
    @deed= FactoryGirl.create(:deed_with_batch)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:deeds)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create deed" do
    assert_difference('Deed.count') do
      post :create, deed: { category: @deed.category, description: @deed.description, name: @deed.name, user_id: @deed.user_id }
    end

    assert_redirected_to deed_path(assigns(:deed))
  end

  test "should show deed" do
    get :show, id: @deed
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @deed
    assert_response :success
  end

  test "should update deed" do
    patch :update, id: @deed, deed: { category: @deed.category, description: @deed.description, name: @deed.name, user_id: @deed.user_id }
    assert_redirected_to deed_path(assigns(:deed))
  end

  test "should destroy deed" do
    assert_difference('Deed.count', -1) do
      delete :destroy, id: @deed
    end

    assert_redirected_to deeds_path
  end
end
