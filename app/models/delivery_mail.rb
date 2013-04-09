# -*- encoding: utf-8 -*-
class DeliveryMail < ActiveRecord::Base
  has_many :delivery_mail_targets, :conditions => "delivery_mail_targets.deleted = 0"
  attr_accessible :bp_pic_group_id, :content, :id, :mail_bcc, :mail_cc, :mail_from, :mail_from_name, :mail_send_status_type, :mail_status_type, :owner_id, :planned_setting_at, :send_end_at, :subject, :lock_version
  after_initialize :default_values

  def default_values
    self.mail_status_type ||= 'unsend'
    self.mail_send_status_type ||= 'ready'
  end
  
  def DeliveryMail.send_mails(id, destination_list)
	  	fetch_key = "mailer: " + Time.now.to_s + " " + rand().to_s
	  	
	  	begin
		  DeliveryMail.
			  where("id=? and mail_send_status_type=? and mail_status_type=? and planned_setting_at<=?",
				  	id, "ready", "unsend", Time.now.to_s(:db)).
			  update_all(:mail_send_status_type => 'running', :updated_user => fetch_key)
			p destination_list.length.to_s
			mails = DeliveryMail.where("id=? and mail_send_status_type=? and updated_user=?", id, "running", fetch_key)	
	  		if mails.length == 1 && destination_list.length >= 1
		  		# 配列に包まれたオブジェクトを取り出す
	  			mail = mails.shift
	  			destination_list.each {|d|
	  				Mailer.del_mail_send(
	  					d,
	  					mail.mail_cc,
	  					mail.mail_bcc,
	  					mail.mail_from,
	  					mail.subject,
	  					mail.content
					).deliver
	  			}
	  			
			  DeliveryMail.
				  where("id=? and mail_send_status_type=? and updated_user=?", id, "running", fetch_key).
				  update_all(:mail_send_status_type => 'finished', :send_end_at => Time.now.to_s(:db))
			else
				raise "Target is Zero."
			end
				
		rescue => e
			p e
			DeliveryMail.
				where("id=? and updated_user=?", id, fetch_key).
				update_all(:mail_send_status_type => 'ready', :updated_user => '')
	  	end
  end
	
	# Private Mailer
	class Mailer < ActionMailer::Base
		def del_mail_send(destination, cc, bcc, from, subject, body)
			mail(
				recipients: destination,
				cc: cc,
				bcc: bcc,
				from: from, 
				subject: subject,
				body: ActionController::Base.new.render_to_string(
					:partial => "delivery_mails/mail_body",
					:locals => {:content => body}
				)
			)
		end
	end
	  
end
