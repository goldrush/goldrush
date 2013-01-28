# -*- encoding: utf-8 -*-
require 'nkf'
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

  def BusinessPartner.export_to_csv
    csv_data = []
    csv_data << "e-mail,Name,ZipCode,Prefecture,Address,Tel,Birthday,Occupation,案件,人材, bp_id, bp_pic_id,担当グループ"
    BpPic.all.each do |x|
      csv_data << [x.email1, x.bp_pic_name,x.business_partner.business_partner_name, "", "", "", "", "", x.business_partner.down_flg, x.business_partner.upper_flg, x.business_partner.id, x.id].join(',')
    end
    return NKF.nkf("-s", csv_data.join("\n"))
  end
  def BusinessPartner.import_from_csv(filename, prodmode=false)
    File.open(filename, "r"){|file| import_from_csv_data(file, prodmode)}
  end

  def BusinessPartner.import_from_csv_data(readable_data, prodmode=false)
    ActiveRecord::Base.transaction do
    require 'csv'
    companies = {}
    pics = {}
    pic_groups = {}
    BusinessPartner.all.each do |x|
      companies[x.business_partner_name.upcase] = [x, []]
    end
    BpPic.all.each do |y|
      pics[y.bp_pic_name] = [y]
    end
    BpPicGroup.all.each do |z|
      pic_groups[z.bp_pic_group_name] = [z]
    end
    CSV.parse(NKF.nkf("-w", readable_data)).each do |row|
      next if row[0] == 'e-mail'
      break if row[0].blank?
      a,b = row[2].split("　")
      a.strip!
      c = row[12]
      email = if prodmode
        row[0]
      else
        "test+" + row[0].sub("@","_") + "@i.applicative.jp"
      end

      if row[10]
        # update
        if update_business_partner = BusinessPartner.where(:id => row[10].to_i).first
          update_business_partner.down_flg = row[8].to_i
          update_business_partner.upper_flg = row[9].to_i
          update_business_partner.save!
          companies[a.upcase] = [update_business_partner, []]
        end
      else
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
      end

      pic = BpPic.new
      pic.business_partner_id = companies[a.upcase][0].id
      name = if row[1] =~ /(.*)様/
        $1
      else
        row[1]
      end
      if pics[name]
        companies[a.upcase][1] << name
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
      else
        if row[11].blank?
          next
        else
          # update
          if update_bp_pic = BpPic.where(:bp_pic_name => name).first
            update_bp_pic.email1 = row[0]
            update_bp_pic.business_partner_id = row[10].to_i
            update_bp_pic.save!
          end
        end
      end
      unless pic_groups[c]
        gr = BpPicGroup.new
        gr.bp_pic_group_name = c
        gr.created_user = 'import'
        gr.updated_user = 'import'
        gr.save!
        pic_groups[c] = [gr]
      end
      db_bp_pic = BpPic.where(:bp_pic_name => name).first
      db_pic_group = BpPicGroup.where(:bp_pic_group_name => c).first
      db_bp_pic_group_details = BpPicGroupDetail.where(:bp_pic_group_id => db_pic_group.id)
      # 担当者存在チェックフラグ
      bp_pic_flg = false
      db_bp_pic_group_details.each do |pic|
        if pic.bp_pic_id == db_bp_pic.id
          bp_pic_flg = true
        end
      end
      if !bp_pic_flg
        gr_detail = BpPicGroupDetail.new
        gr_detail.bp_pic_group_id = db_pic_group.id
        gr_detail.bp_pic_id = db_bp_pic.id
        gr_detail.save!
      end
    end
  end
end
end
