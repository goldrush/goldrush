require 'test_helper'

class RemarksControllerTest < ActionController::TestCase
  setup do
    @remark = remarks(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:remarks)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create remark" do
    assert_difference('Remark.count') do
      post :create, remark: { id: @remark.id, owner_id: @remark.owner_id, rating: @remark.rating, remark_content: @remark.remark_content, remark_key: @remark.remark_key, remark_target_id: @remark.remark_target_id }
    end

    assert_redirected_to remark_path(assigns(:remark))
  end

  test "should show remark" do
    get :show, id: @remark
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @remark
    assert_response :success
  end

  test "should update remark" do
    put :update, id: @remark, remark: { id: @remark.id, owner_id: @remark.owner_id, rating: @remark.rating, remark_content: @remark.remark_content, remark_key: @remark.remark_key, remark_target_id: @remark.remark_target_id }
    assert_redirected_to remark_path(assigns(:remark))
  end

  test "should destroy remark" do
    assert_difference('Remark.count', -1) do
      delete :destroy, id: @remark
    end

    assert_redirected_to remarks_path
  end
end
