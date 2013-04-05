class BpPicGroup < ActiveRecord::Base
  has_many :bp_pic_group_details, :conditions => "bp_pic_group_details.deleted = 0"
  attr_accessible :bp_pic_group_name, :memo, :lock_version
end
