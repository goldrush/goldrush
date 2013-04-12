# -*- encoding: utf-8 -*-
require 'auto_type_name'
include AutoTypeName
class DeliveryMail < ActiveRecord::Base
  has_many :delivery_mail_targets, :conditions => "delivery_mail_targets.deleted = 0"
  attr_accessible :bp_pic_group_id, :content, :id, :mail_bcc, :mail_cc, :mail_from, :mail_from_name, :mail_send_status_type, :mail_status_type, :owner_id, :planned_setting_at, :send_end_at, :subject, :lock_version
  after_initialize :default_values

  def default_values
    self.mail_status_type ||= 'unsend'
    self.mail_send_status_type ||= 'ready'
  end
  
  # Broadcast Mails
  def DeliveryMail.send_mails
    fetch_key = Time.now.to_s + " " + rand().to_s
      
    DeliveryMail.
      where("mail_status_type=? and mail_send_status_type=? and planned_setting_at<=?",
             'unsend', 'ready', Time.now).
      update_all(:mail_send_status_type => 'running', :created_user => fetch_key)
    
    begin
      DeliveryMail.where(:created_user => fetch_key).each {|mail|
        mail.delivery_mail_targets.each {|target|
          email = target.bp_pic.email1
          body = mail.content.
            gsub("%%bp_pic_name%%", target.bp_pic.bp_pic_name).
            gsub("%%business_partner_name%%", target.bp_pic.business_partner.business_partner_name)
          
          Mailer.send_del_mail(
            email,
            mail.mail_cc,
            mail.mail_bcc,
            mail.mail_from,
            mail.subject,
            body
          ).deliver
        }
      }
    rescue => e
      error_str = "Delivery Mail Send Error: " + e
      SystemLog.error('delivery mail', 'mail send error',  error_str, 'delivery mail')
    end
      
    DeliveryMail.
      where(:created_user => fetch_key).
      update_all(:mail_status_type => 'send',:mail_send_status_type => 'finished',:send_end_at => Time.now)
  end
  
  # Private Mailer
  class Mailer < ActionMailer::Base
    def send_del_mail(destination, cc, bcc, from, subject, body)
      mail(
        recipients: destination,
        cc: cc,
        bcc: bcc,
        from: from, 
        subject: subject,
        body: body
      )
    end
  end
  
end
