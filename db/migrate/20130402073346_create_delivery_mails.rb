class CreateDeliveryMails < ActiveRecord::Migration
  def change
    create_table :delivery_mails do |t|
      t.primary_key :id
      t.integer :owner_id
      t.integer :bp_pic_group_id
      t.string :mail_status_type
      t.string :subject
      t.string :content
      t.string :mail_from_name
      t.string :mail_from
      t.string :mail_cc
      t.string :mail_bcc
      t.string :planned_setting_at
      t.string :mail_send_status_type
      t.string :send_end_at

      t.timestamps
    end
  end
end
