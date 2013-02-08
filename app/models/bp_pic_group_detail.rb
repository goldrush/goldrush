class BpPicGroupDetail < ActiveRecord::Base
  attr_accessible :bp_pic_group_id, :bp_pic_id, :id, :memo, :owner_id, :lock_version
end
