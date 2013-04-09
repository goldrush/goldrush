# -*- encoding: utf-8 -*-
module ImportMailHelper

  def flg_links(import_mail)
    _id = import_mail.id
    link_to(raw("<span id='biz_offer_icon_#{_id}' style='#{_style(import_mail.biz_offer_flg)}'>案件</span>"), "#", :onclick => "return changeFlg(#{_id}, 'biz_offer');") + "|" +
    link_to(raw("<span id='bp_member_icon_#{_id}' style='#{_style(import_mail.bp_member_flg)}'>人材</span>"), "#", :onclick => "return changeFlg(#{_id}, 'bp_member');") + "|" +
    link_to(raw("<span id='unwanted_icon_#{_id}' style='#{_style(import_mail.unwanted)}'>不要</span>"), "#", :onclick => "return changeFlg(#{_id}, 'unwanted');")
  end
  
  def _style(flg)
    [_b(flg), _c(flg)].compact.join(";");
  end
  def _b(flg)
    flg.to_i == 1 ? "font-weight: bold" : nil
  end
  def _c(flg)
    flg.to_i == 1 ? "color: black" : nil
  end
  
end
