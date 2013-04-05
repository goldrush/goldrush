require 'test_helper'

class DeliveryMailsControllerTest < ActionController::TestCase
  setup do
    @delivery_mail = delivery_mails(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:delivery_mails)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create delivery_mail" do
    assert_difference('DeliveryMail.count') do
      post :create, delivery_mail: { bp_pic_group_id: @delivery_mail.bp_pic_group_id, content: @delivery_mail.content, id: @delivery_mail.id, mail_bcc: @delivery_mail.mail_bcc, mail_cc: @delivery_mail.mail_cc, mail_from: @delivery_mail.mail_from, mail_from_name: @delivery_mail.mail_from_name, mail_send_status_type: @delivery_mail.mail_send_status_type, mail_status_type: @delivery_mail.mail_status_type, owner_id: @delivery_mail.owner_id, planned_setting_at: @delivery_mail.planned_setting_at, send_end_at: @delivery_mail.send_end_at, subject: @delivery_mail.subject }
    end

    assert_redirected_to delivery_mail_path(assigns(:delivery_mail))
  end

  test "should show delivery_mail" do
    get :show, id: @delivery_mail
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @delivery_mail
    assert_response :success
  end

  test "should update delivery_mail" do
    put :update, id: @delivery_mail, delivery_mail: { bp_pic_group_id: @delivery_mail.bp_pic_group_id, content: @delivery_mail.content, id: @delivery_mail.id, mail_bcc: @delivery_mail.mail_bcc, mail_cc: @delivery_mail.mail_cc, mail_from: @delivery_mail.mail_from, mail_from_name: @delivery_mail.mail_from_name, mail_send_status_type: @delivery_mail.mail_send_status_type, mail_status_type: @delivery_mail.mail_status_type, owner_id: @delivery_mail.owner_id, planned_setting_at: @delivery_mail.planned_setting_at, send_end_at: @delivery_mail.send_end_at, subject: @delivery_mail.subject }
    assert_redirected_to delivery_mail_path(assigns(:delivery_mail))
  end

  test "should destroy delivery_mail" do
    assert_difference('DeliveryMail.count', -1) do
      delete :destroy, id: @delivery_mail
    end

    assert_redirected_to delivery_mails_path
  end
end
