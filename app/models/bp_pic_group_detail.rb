class BpPicGroupDetail < ActiveRecord::Base
  belongs_to :bp_pic
  attr_accessible :bp_pic_group_id, :bp_pic_id, :id, :memo, :owner_id, :suspended, :lock_version
  
  def suspended?
    suspended == 1
  end
end
