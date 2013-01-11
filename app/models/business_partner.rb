# -*- encoding: utf-8 -*-
class BusinessPartner < ActiveRecord::Base
  before_create :set_default
  include AutoTypeName
  has_many :businesses, :conditions => ["businesses.deleted = 0"]
  has_many :bp_pics, :conditions => ["bp_pics.deleted = 0"]
  has_many :biz_offers, :conditions => ["biz_offers.deleted = 0"]
  has_many :bp_members, :conditions => ["bp_members.deleted = 0"]

  validates_presence_of :business_partner_name, :business_partner_short_name, :business_partner_name_kana
  validates_uniqueness_of :business_partner_code, :case_sensitive => false, :allow_blank => true
  validates_uniqueness_of :business_partner_name, :case_sensitive => false

  def set_default
    self.sales_code = "S" + SysConfig.get_seq_0('sales_code', 7)
  end

  def address
    "#{address1}#{address2}"
  end
  
  def business_partner_code_name
    self.sales_code + " " + business_partner_name
  end

  def BusinessPartner.immport_from_csv(filename, prodmode=false)
    ActiveRecord::Base.transaction do
    require 'csv'
    companies = {}
    CSV.read(filename).each do |row|
      next if row[0] == 'e-mail'
      break if row[0].blank?
      a,b = row[2].split("　")
      a.strip!
      email = if prodmode
        row[0]
      else
        "test+" + row[0].sub("@","_") + "@i.applicative.jp"
      end
      unless companies[a.upcase]
        bp = BusinessPartner.new
        bp.business_partner_name = a
        bp.business_partner_short_name = a
        bp.business_partner_name_kana = a
        bp.sales_status_type = 'prospect'
	bp.upper_flg = row[8].to_i
	bp.down_flg = row[9].to_i
	if row[1].include?('担当者')
          bp.email = email
	end
	bp.created_user = 'import'
	bp.updated_user = 'import'
	bp.save!
	companies[a.upcase] = [bp, []]
      end
      pic = BpPic.new
      pic.business_partner_id = companies[a.upcase][0].id
      name = if row[1] =~ /(.*)様/
        $1
      else
        row[1]
      end
      unless companies[a.upcase][1].include? name
        companies[a.upcase][1] << name
        pic.bp_pic_name = name
        pic.bp_pic_short_name = name
        pic.bp_pic_name_kana = name
        pic.email1 = email
        pic.created_user = 'import'
        pic.updated_user = 'import'
        pic.save!
      end
      end
    end
  end
end
