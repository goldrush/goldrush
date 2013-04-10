class Remark < ActiveRecord::Base
  attr_accessible :id, :owner_id, :rating, :remark_content, :remark_key, :remark_target_id, :lock_version

  validates_presence_of :remark_content

  def get_created_user
    User.find(:first, :conditions => ["deleted = 0 and login = ?", created_user])
  end
end
