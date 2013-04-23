# -*- encoding: utf-8 -*-
module ImportMailHelper
  # 各メールのフラグを変更するリンクタグを生成する
  def build_flag_link(text, mode, style_flag, import_mail)
    # 対象のリンク生成モードで、メールに紐付くレコードがある場合、"true"になる
    reg = is_registerd?(import_mail, mode)
    # spanタグにつけるIDを生成する
    span_id = "#{mode}_icon_#{import_mail.id}"
    # spanタグのスタイルを取得する
    style = flag_style( import_mail.send(style_flag), reg )
    # onclickイベントを生成する
    onclick = "return changeFlg(#{import_mail.id}, '#{mode}');"
    
    # 各タグを生成する
    span = content_tag(:span, :id => span_id, :style => style ){ text }
    link = content_tag(:a, :href => "#", :onclick => onclick){ span }
    
    # 紐づくレコードがある場合、リンクにしない
    # メールの解析をしたら、案件、人材を手動で振り分ける事はない想定
    # 解析テンプレートがない場合のみ
    if(reg)
      return raw(span)
    else
      return raw(link)
    end
  end
  
  def flag_style(flg, registered)
    ["margin:0px","padding:0px","width:34%",flag_font(flg), flag_color(flg), flag_bg(registered)].compact.join(";");
  end
  
  def flag_font(flg)
    flg.to_i == 1 ? "font-weight: bold" : nil
  end
  
  def flag_color(flg)
    flg.to_i == 1 ? "color: blue" : nil
  end
  
  def flag_bg(flg)
    "background-color: gray" if flg
  end
  
  def is_registerd?(import_mail, reg_to)
    case reg_to
    when :biz_offer
      return import_mail.biz_offers.exists?
    when :bp_member
      return import_mail.bp_members.exists?
    end
    # それ以外は常にfalse
    return false
  end
  
  # オブジェクトが指定したIDの取り込みメールに紐付いているかを調べる
  # object         : 検査対象オブジェクト
  # import_mail_id : 対象の取り込みメールID
  def has_related_import_mail(object, import_mail_id)
    result = false
    if object.has_method(:import_mail_id)
      result = object.import_mail_id == import_mail_id
    end
    return result;
  end
  
  # 以下、リンク生成ヘルパー
  
  # 
  def link_to_import_api(text)
  	link_to text, {:controller => :api, :action => :import_mail_pop3}, :confirm => "POP3にてメールを取り込みます。よろしいですか？"
  end
  
  def link_to_detail(import_mail, back_to_url)
  	link_to h(import_mail.mail_subject), :action => :show, :id => import_mail, :back_to => back_to_url
  end
  
  def link_to_bp_detail(import_mail)
  	link_to import_mail.mail_sender_name, :controller => :business_partner, :action => :show, :id => import_mail.business_partner_id
  end
  
  def link_to_biz_create(text, import_mail)
  	link_to text, url_for(:controller => 'analysis_template', :action => 'list', :popup => 1, :mode => 'biz_offer', :import_mail_id => import_mail), :class => :analysis_mail_link
  end
  
  def link_to_hresource_create(text, import_mail)
  	link_to text, url_for(:controller => 'analysis_template', :action => 'list', :popup => 1, :mode => 'bp_member', :import_mail_id => import_mail), :class => :analysis_mail_link
  end
  
  def link_to_bp_create(text, import_mail)
    link_to text, url_for(:controller => 'business_partner', :action => 'new', :popup => 1, :import_mail_id => import_mail), :class => :analysis_mail_link
  end
  
end
