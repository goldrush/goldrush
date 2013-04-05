# -*- encoding: utf-8 -*-
require 'iso2022jp_mailer'
class UserNotifier < Iso2022jpMailer
  def signup_notification(user)
    setup_email(user)
    @subject    += base64('仮登録完了のお知らせ')
    @body[:url]  = user.activate_url
  end
  
  def activation(user)
    setup_email(user)
    @subject    += base64('登録完了しました')
    @body[:url]  = user.site_url
  end
  
  def forgot_password(user)
    setup_email(user)
    @subject    += base64('ユーザ確認メールです')
    @body[:url]  = user.forgot_password_url
  end
  
  protected
  def setup_email(user)
    settings = ActionMailer::Base.smtp_settings
    if settings[:user_name].include? "@"
      @from = settings[:user_name].to_s
    else
      @from = settings[:user_name].to_s + "@" + settings[:domain].to_s
    end
    @recipients  = "#{user.email}"
    @subject     = "[PP2D] "
    @sent_on     = Time.now
    @body[:user] = user
    @body[:from] = @from
  end
end
