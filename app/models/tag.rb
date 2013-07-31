# -*- encoding: utf-8 -*-
class Tag < ActiveRecord::Base
  has_many :tag_details, :conditions => ["tag_details.deleted = 0"]
  has_many :tag_journals, :conditions => ["tag_journals.deleted = 0"]
  
  before_save :clear_tag_cache
  
  def clear_tag_cache
    Tag.clear_tag_cache
  end

  # タグの文字列を受け取って正規化する
  # 正規化=>小文字化、",",半角スペース、全角スペースで区切り、文字列の配列として戻す
  def Tag.normalize_tag(tag_string)
    return tag_string.to_s.downcase.split(",").delete_if{|x| x.blank? }.sort.uniq
  end

  def Tag.create_tags!(key, parent_id, tag_string)
    splited_tags = Tag.normalize_tag(tag_string)
    splited_tags.each do |tag_text|
      unless t = Tag.find(:first, :conditions => ["tag_text = ? and tag_key = ? and deleted = 0", tag_text, key])
        t = Tag.new
        t.tag_text = tag_text
        t.tag_key = key
#        t.created_user = self.updated_user
#        t.updated_user = self.updated_user
        t.save!
      end
      TagDetail.create_tags!(t.id, parent_id, tag_text, key)
      TagJournal.put_journal!(t.id, 1)
      # TODO: 利用者が少ないため、ここで集計しているが本来cronで定期的に集計する
      # 利用者が増えたら対応
    end
    #TagJournal.summry_tags!
  end

  def Tag.update_tags!(key, parent_id, tag_string)
     # 旧Tagに対する処理
    details = TagDetail.find(:all, :joins => :tag, :readonly => false, :conditions => ["tags.tag_key = ? and parent_id = ? and tags.deleted = 0 and tag_details.deleted = 0", key, parent_id])
    details.each do |detail|
      detail.deleted = 9
      detail.deleted_at = Time.now
#      deteled_user = '???'
      detail.save!
      TagJournal.put_journal!(detail.tag_id, -1)
    end
    Tag.create_tags!(key, parent_id, tag_string)
  end

  def Tag.delete_tags!(key, parent_id)
    Tag.update_tags!(key, parent_id, "")
  end
  
  def Tag.clear_tag_cache
    @@good_tags = nil
    @@bad_tags = nil
  end
  Tag.clear_tag_cache
  
  def Tag.good_tags
    @@good_tags || (@@good_tags = starred_tags(1))
  end

  def Tag.bad_tags
    @@bad_tags || (@@bad_tags = starred_tags(2))
  end

  def Tag.starred_tags(star)
    where(deleted: 0, tag_key: "import_mails", starred: star).map{|x| x.tag_text}
  end
  
  # strに対して、全角半角変換を行い、不要な文字列(メアド、URL)を削除する
  def Tag.pre_proc_body(str)
    require 'zen2han'
    Zen2Han.toHan(str).gsub(/[\_\-\+\.\w]+@[\-a-z0-9]+(\.[\-a-z0-9]+)*\.[a-z]{2,6}/i, "").gsub(/https?:\/\/\w[\w\.\-\/]+/i,"")
  end

  def Tag.analyze_skill_tags(body)
    require 'string_util'
    words = StringUtil.detect_words(body).inject([]) do |r,item|
      arr = item.split(" ")
      arr.each do |w| # スペースで分割
        # C++用スペシャルロジック
        StringUtil.splitplus(w).each do |ww| # +で分割
          StringUtil.breaknum(ww).each do |www| # 数字の前後で分割(数字のみは排除)
            r << www
          end
        end
      end
      r << arr.join("")
    end
    words = words.uniq.reject{|w|
      Tag.ignores.include?(w.downcase) || w =~ /^\d/ || w.length == 1 # 辞書に存在するか、数字で始まる単語、1文字
    }
    # C言語用スペシャルロジック
    if body =~ /(^|[^a-zA-Z])(C)([^a-zA-Z#\+]|$)/
      words << $2
    end
    words.join(",")
  end

  def Tag.ignores
    ["e-mail", "email", "fax", "jp", "mail", "mailto", "new", "ng", "or", "or2", "or3", "or4",
     "os", "pc", "pg", "phone", "phs", "pj", "pmi", "popteen", "pr", "pro", "se", "service", "ses", "tel", "url", "zip"]
  end

end

