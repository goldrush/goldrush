class Remark < ActiveRecord::Base
  attr_accessible :id, :owner_id, :rating, :remark_content, :remark_key, :remark_target_id, :lock_version
end
