# -*- encoding: utf-8 -*-
module ApplicationUtil
  def self_data?(user_id)
    (self.user_id == user_id)
  end

  def fixed?
    self.base_application.approval_status_type == 'fixed'
  end

  def approver?(approver_id)
    ApplicationApproval.application_approver?(self, approver_id)
  end

  def canceled?
    self.base_application.approval_status_type == 'canceled'
  end

  def get_color_by_approval_status_type(approval_status_type)
    case approval_status_type
      when 'entry','approved'
        conf_entry = SysConfig.get_color_approval_status_type_entry
        return conf_entry.value1 if conf_entry
      when 'fixed'
        conf_approved = SysConfig.get_color_approval_status_type_approved
        return conf_approved.value1 if conf_approved
      when 'reject'
        conf_reject = SysConfig.get_color_approval_status_type_reject
        return conf_reject.value1 if conf_reject
    end
    return nil
  end
  
end

