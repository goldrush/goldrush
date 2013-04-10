# -*- encoding: utf-8 -*-
class AnalysisTemplate < ActiveRecord::Base
  include AutoTypeName

  validates_presence_of :analysis_template_name
  
  belongs_to :business_partner
  belongs_to :bp_pic
  has_many :analysis_template_items, :conditions => ["analysis_template_items.deleted = 0"]
  
  # メール解析処理のメイン
  # 考え方
  # AnalysisTemplateItemより、対象のテンプレートを取得
  # メールのbodyに対して逐次正規表現マッチを行う
  #
  #
  def AnalysisTemplate.analyze(analysis_template_id, import_mail, models)#biz_offer, business
    AnalysisTemplateItem.find(:all, :conditions => ["deleted = 0 and analysis_template_id = ?", analysis_template_id]).each do |at_item|
      option = at_item.ignore_flg == 1 ? Regexp::MULTILINE : nil
      if import_mail.mail_body =~ Regexp.new(at_item.pattern, option)
        models.each do |model|
          next unless model.class.name == at_item.target_table_name.classify
#            puts">>>>>>>>>>>>table_name  : "+model.class.name
#            puts">>>>>>>>>>>>column_name : "+at_item.target_column_name
#            puts">>>>>>>>>>>>value       : "+$1

          unless at_item.before_set_code.blank?
            eval <<EOS
              def AnalysisTemplate.before_set(model, at_item, str)
                #{at_item.before_set_code}
              end
EOS
            before_set(model, at_item, $1)
          end

          model.send("#{at_item.target_column_name}=", $1)

          unless at_item.after_set_code.blank?
            eval <<EOS
              def AnalysisTemplate.after_set(model, at_item, str)
                #{at_item.after_set_code}
              end
EOS
            after_set(model, at_item, $1)
          end
          
        end # models.each
      end # each |at_item|
    end
  end

end
