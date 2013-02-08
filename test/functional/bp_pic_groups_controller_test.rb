require 'test_helper'

class BpPicGroupsControllerTest < ActionController::TestCase
  setup do
    @bp_pic_group = bp_pic_groups(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:bp_pic_groups)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create bp_pic_group" do
    assert_difference('BpPicGroup.count') do
      post :create, bp_pic_group: { bp_pic_group_name: @bp_pic_group.bp_pic_group_name, id: @bp_pic_group.id, memo: @bp_pic_group.memo }
    end

    assert_redirected_to bp_pic_group_path(assigns(:bp_pic_group))
  end

  test "should show bp_pic_group" do
    get :show, id: @bp_pic_group
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @bp_pic_group
    assert_response :success
  end

  test "should update bp_pic_group" do
    put :update, id: @bp_pic_group, bp_pic_group: { bp_pic_group_name: @bp_pic_group.bp_pic_group_name, id: @bp_pic_group.id, memo: @bp_pic_group.memo }
    assert_redirected_to bp_pic_group_path(assigns(:bp_pic_group))
  end

  test "should destroy bp_pic_group" do
    assert_difference('BpPicGroup.count', -1) do
      delete :destroy, id: @bp_pic_group
    end

    assert_redirected_to bp_pic_groups_path
  end
end
