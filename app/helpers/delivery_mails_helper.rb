# -*- encoding: utf-8 -*-
module DeliveryMailsHelper

  def row_style(delivery_mail)
    if    delivery_mail.canceled?
      return 'canceled'
    elsif delivery_mail.unsend?
      return 'unsend'
    elsif delivery_mail.delivery_errors.count > 0
      return 'warn'
    else
      return 'send'
    end
  end

  def group?
    return !params[:bp_pic_group_id].blank?
  end

  def mail_to(delivery_mail)
    if delivery_mail.group?
      #グループメールの場合
      if bp_pic_group = delivery_mail.bp_pic_group
        return content_tag(:div, bp_pic_group.bp_pic_group_name, {:style=>"overflow: hidden;height:1.5em;word-wrap: break-word;word-break: break-all;", :title=>bp_pic_group.bp_pic_group_name})
      end
    else
      #即席メールの場合
      targets =[]
      delivery_mail.delivery_mail_targets.each do |target|
        next if !delivery_mail.unsend? && target.message_id.blank?
        targets.push(target.bp_pic.business_partner_name + " " + target.bp_pic.bp_pic_short_name)
      end
      return content_tag(:div, targets.join(", "), {:style=>"overflow: hidden;height:1.5em;word-wrap: break-word;word-break: break-all;", :title=>targets.join("\n")})
    end
    return ""
  end

  def get_biz_offer_name
    BizOffer.find(@delivery_mail.biz_offer_id)
  end

  def get_bp_member_name
    BpMember.find(@delivery_mail.bp_member_id)
  end

  def mail_from_list
    user_list = User.includes(:employee).where(["users.owner_id = ? and users.deleted = 0 and employees.resignation_date is null", current_user.owner_id]).map {|x| [x.formated_mail_from]}
    user_list.unshift("#{SysConfig.get_value(:delivery_mails, :default_from_name)} <#{SysConfig.get_value(:delivery_mails, :default_from)}>")
  end
end
