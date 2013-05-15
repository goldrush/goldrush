class BusinessPartnerGoogleImporter < BusinessPartner

  # ���h�Ǘ��A�J�E���g����o�͂��ꂽCSV�t�@�C�����C���|�[�g(google.csv)
  def BusinessPartnerGoogleImporter.import_google_csv_data(readable_file, prodmode=false)
    employees = Employee.map_for_googleimport
    ActiveRecord::Base.transaction do
      require 'csv'
      header = nil
      CSV.parse(NKF.nkf("-w", readable_file)).each {|row|
        if header
          r = BusinessPartnerGoogleImporter.analyze_row(header, row)
        else
          header = BusinessPartnerGoogleImporter.analyze_header(row)
          next
        end
        # �e�f�[�^�𐮌`���ĕϐ��֑��
        phone_number = {r["Phone 1 - Type"] => r["Phone 1 - Value"], r["Phone 2 - Type"] => r["Phone 2 - Value"], r["Phone 3 - Type"] => r["Phone 3 - Value"]}
        email_address = {r["E-mail 1 - Type"] => r["E-mail 1 - Value"], r["E-mail 2 - Type"] => r["E-mail 2 - Value"]}

        email1 = email_address['* Work']
        email2 = email_address['Work']
        unless prodmode
          email1 = StringUtil.to_test_address(email1)
          email2 = StringUtil.to_test_address(email2)
        end

        if bp_pic = BpPic.where(:email1 => email1, :deleted => 0).first
          bp = bp_pic.business_partner
        else
          bp_pic = BpPic.new
          if bp = BusinessPartner.where(:business_partner_name => r["Organization 1 - Name"], :deleted => 0).first
            bp_pic.business_partner = bp
          else
            bp = BusinessPartner.new
            bp_pic.business_partner = bp
          end
        end

        bp_pic.attributes = {
          :bp_pic_name => r["Name"],
          :bp_pic_short_name => r["Family Name"],
          :bp_pic_name_kana => r["Name"],
          :position => r["Organization 1 - Title"],
          :email1 => email1,
          :email2 => email2,
          :tel_mobile => colon_2_comma(phone_number['Mobile'])
        }.reject{|k,v| v.blank?}

        tags = BusinessPartnerGoogleImporter.mysplit(r["Group Membership"])
        tags.each do |tag|
          if sales_pic_id = employees[tag]
            bp_pic.sales_pic_id = sales_pic_id
            break
          end
        end

        bp.attributes = {
          :business_partner_name => r["Organization 1 - Name"],
          :business_partner_short_name => r["Organization 1 - Name"],
          :business_partner_name_kana => r["Organization 1 - Name"],
          :url => r["Website 1 - Value"],
          :zip => get_first(r["Address 1 - Postal Code"]),
          :address2 => get_first(r["Address 1 - Street"]),
          :address1 => get_first(r["Address 1 - Region"]),
          :tel => colon_2_comma(phone_number['Work']),
          :fax => colon_2_comma(phone_number['Work Fax']),
          :sales_status_type => 'prospect'
        }.reject{|k,v| v.blank?}

        if tags.include?("SES")
          bp.upper_flg = 1
          bp.down_flg = 1
        end

        bp.created_user = 'import'
        bp.updated_user = 'import' if bp.new_record?
        bp.save!

        bp_pic.created_user = 'import'
        bp_pic.updated_user = 'import' if bp_pic.new_record?
        bp_pic.save!
      }
    end
  end
  
  # helper methods 4 import_google_csv_data
  def BusinessPartnerGoogleImporter.mysplit(str)
    str.to_s.split(":::").map{|x| x.strip}
  end

  def BusinessPartnerGoogleImporter.get_first(str)
    mysplit(str).first
  end
  
  def BusinessPartnerGoogleImporter.colon_2_comma(str)
    str.to_s.gsub(" ::: ", ", ")
  end
  
  def BusinessPartnerGoogleImporter.analyze_header(row)
    headers = {}
    row.each_with_index do |col, i|
      headers[col] = i
    end
    headers
  end

  def BusinessPartnerGoogleImporter.analyze_row(header, row)
    r = {}
    header.each do |k,v|
      r[k] = row[v].to_s
    end
    r
  end

  COLUMN_NAMES = [
    "Name",
    "Given Name",
    "Additional Name",
    "Family Name",
    "Yomi Name",
    "Given Name Yomi",
    "Additional Name Yomi",
    "Family Name Yomi",
    "Name Prefix",
    "Name Suffix",
    "Initials",
    "Nickname",
    "Short Name",
    "Maiden Name",
    "Birthday",
    "Gender",
    "Location",
    "Billing Information",
    "Directory Server",
    "Mileage",
    "Occupation",
    "Hobby",
    "Sensitivity",
    "Priority",
    "Subject",
    "Notes",
    "Group Membership",
    "E-mail 1 - Type",
    "E-mail 1 - Value",
    "E-mail 2 - Type",
    "E-mail 2 - Value",
    "Phone 1 - Type",
    "Phone 1 - Value",
    "Phone 2 - Type",
    "Phone 2 - Value",
    "Phone 3 - Type",
    "Phone 3 - Value",
    "Address 1 - Type",
    "Address 1 - Formatted",
    "Address 1 - Street",
    "Address 1 - City",
    "Address 1 - PO Box",
    "Address 1 - Region",
    "Address 1 - Postal Code",
    "Address 1 - Country",
    "Address 1 - Extended Address",
    "Organization 1 - Type",
    "Organization 1 - Name",
    "Organization 1 - Yomi Name",
    "Organization 1 - Title",
    "Organization 1 - Department",
    "Organization 1 - Symbol",
    "Organization 1 - Location",
    "Organization 1 - Job Description",
    "Website 1 - Type",
    "Website 1 - Value"]

end