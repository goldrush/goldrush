# -*- encoding: utf-8 -*-
require 'auto_type_name'
require 'application_util'
class BaseApplication < ActiveRecord::Base
  include AutoTypeName
  include ApplicationUtil

  belongs_to :user

  has_one :monthly_working, :conditions => "monthly_workings.deleted = 0"
  has_one :weekly_report, :conditions => "weekly_reports.deleted = 0"

  has_one :payment_per_month, :conditions => "payment_per_months.deleted = 0"
  has_one :payment_per_case, :conditions => "payment_per_cases.deleted = 0"

  has_one :expense_application, :conditions => "expense_applications.deleted = 0"
  has_one :holiday_application, :conditions => "holiday_applications.deleted = 0"
  has_one :other_application, :conditions => "other_applications.deleted = 0"
  has_one :business_trip_application, :conditions => "business_trip_applications.deleted = 0"

  has_many :application_approvals, :conditions => "application_approvals.deleted = 0", :order => "application_approvals.approver_id"

  def application_approver?(approver_id)
    application_approvals.each do |application_approval|
      return true if application_approval.approver_id == approver_id
    end
    return false
  end

  def BaseApplication.monthly_application_typs
    ['monthly_working_app']
  end


  def BaseApplication.weekly_application_typs
    ['weekly_report_app']
  end

  def BaseApplication.working_application_typs
    ['business_trip_app','holiday_app','other_app']
  end
  
  def BaseApplication.all_working_application_typs
    ['business_trip_app','holiday_app','other_app','monthly_working_app','weekly_report_app']
  end

  def BaseApplication.expense_application_typs
#    ['payment_per_month_app','payment_per_case_app','expense_app','business_trip_app']
    ['expense_app']
  end

  # 休暇申請の承認区分を変更する
  def change_approval_status(approver, &block)
    # すべての承認者が承認しているか調べる
    all_fixed = true
    reject = false
    approved = false
#    ActiveRecord::Base.connection.clear_query_cache()
#    ApplicationApproval.find(:all, :conditions => ["base_application_id = ? and deleted = 0 and deleted != 9", self.id]).each do |application_approval|
    self.application_approvals.each do |application_approval|
      all_fixed = false unless application_approval.approval_status_type == 'approved'
      reject = true if application_approval.approval_status_type == 'reject'
      approved = true if application_approval.approval_status_type == 'approved'
    end
    # 承認以外が一人でもいる場合は申請中状態（全員承認中から一人解除したケース）
    if self.approval_status_type == 'fixed' and !all_fixed
      self.approval_status_type = 'entry'
      self.approval_date = nil
      self.unfixed_flg = 1
      self.updated_user = approver
      self.save!
      block.call(self) if block_given?
    # base_applicationsのステータスが未確定状態だが、全員が承認状態の場合は承認にする
    elsif self.approval_status_type != 'fixed' and all_fixed # entry, retry, reject
      self.approval_status_type = 'fixed'
      self.approval_date = Date.today
      self.unfixed_flg = 0
      self.updated_user = approver
      self.save!
      block.call(self) if block_given?
    # base_applicationsのステータスが承認状態で全員が承認状態の場合はここにこないはず
    elsif self.approval_status_type == 'fixed' and all_fixed
      raise "確定されているbase_applicationに対して、確定への変更指示が出されました"
    # それ以外
    else
      if reject
        self.approval_status_type = 'reject'
      elsif approved
        self.approval_status_type = 'approved'
      else
        self.approval_status_type = 'entry'
      end
        self.approval_date = nil
        self.unfixed_flg = 0
        self.updated_user = approver
        self.save!
    end
  end

  # 申請取消処理
  def cancel!(login_user)
    self.application_approvals.each do |application_approval|
      application_approval.approval_status_type = 'canceled'
      application_approval.approval_date = nil
      application_approval.updated_user = login_user
      application_approval.save!
    end
    self.approval_status_type = 'canceled'
    self.approval_date = nil
    self.updated_user = login_user
    self.save!
  end

  def cancel_application!(login_user)
    case self.application_type
      when 'monthly_working_app'
        self.cancel!(login_user)
      when 'weekly_report_app'
        self.cancel!(login_user)
      when 'payment_per_month_app'
        self.cancel!(login_user)
        self.payment_per_month.cutoff_status_type = 'open'
        self.payment_per_month.updated_user = login_user
        self.payment_per_month.save!
        self.payment_per_month.expense_details.each do |detail|
          next if !detail.payment_per_case_id.blank?
          detail.cutoff_status_type = 'open'
          detail.updated_user = login_user
          detail.save!
        end
        self.deleted = 9
        self.updated_user = login_user
        self.save!
      when 'payment_per_case_app'
        self.cancel!(login_user)
        self.payment_per_case.deleted = 9
        self.payment_per_case.updated_user = login_user
        self.payment_per_case.save!
        self.payment_per_case.expense_details.each do |detail|
          next if detail.payment_per_case_id.blank?
          detail.payment_per_case_id = nil
          detail.cutoff_status_type = 'open'
          detail.updated_user = login_user
          detail.save!
        end
        self.deleted = 9
        self.updated_user = login_user
        self.save!
      when 'business_trip_app'
        self.business_trip_application.get_all_daily_workings.each do |daily_working|
          daily_working = DailyWorking.find(daily_working.id)
          daily_working.clear_daily_working!(login_user)
        end
      when 'holiday_app'
        self.holiday_application.get_daily_workings.each do |daily_working|
          daily_working = DailyWorking.find(daily_working.id)
          daily_working.clear_daily_working!(login_user)
        end
      when 'other_app'
        daily_working = self.other_application.get_daily_working
        daily_working.clear_daily_working!(login_user)
      when 'expense_app'
        self.cancel!(login_user)
    end
  end

  def get_color_approval_status_type
    return get_color_by_approval_status_type(self.approval_status_type)
  end
  
  def payment_app?
    ['payment_per_month_app','payment_per_case_app'].include?(application_type)
  end

  def entry?
    ['entry','retry'].include?(self.approval_status_type)
  end

  def canceled?
    self.approval_status_type == 'canceled'
  end

  def fixed?
    self.approval_status_type == 'fixed'
  end

  def rejected?
    self.approval_status_type == 'reject'
  end

  def approved?
    self.approval_status_type == 'approved'
  end

  def can_edit?
    entry? && !payment_app?
  end

  def can_cancel?
#    !fixed? && !canceled?
    !canceled?
  end

  def can_retry?
    rejected? && !payment_app?
  end

  def can_back?
    !payment_app?
  end
  
  def expense_app?
    ['expense_app'].include?(application_type)
  end


  def monthly_working_comp_reset
    user = User.find(self.user_id)
    vacation = user.vacation
    next_month = self.monthly_working.base_month.next_month
    before_month_count = SysConfig.get_before_month_count
    logger.info "Start month: #{next_month.start_date}"
    # 当月を含まずに、before_month_count+1分もってくる(現在月にとっての有効月)
    monthes = BaseMonth.find(:all, :conditions => ["deleted = 0 and start_date < ?", next_month.start_date.to_date], :order => "start_date desc", :limit => (before_month_count + 1)).reverse
    monthes.each{|month|
      logger.info " >> month: " + month.start_date.to_s
puts">==>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>base_monthes.id : #{month.id}"
      next unless monthly_working = MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and base_month_id = ?", user.id, month.id])
      
      # monthly_workingの代休使用時間を戻す
puts">==>>>>>>>>>>>>>>>>>>>>>resist_monthly_working.id : #{monthly_working.id}"
      monthly_working.compensatory_used_total = monthly_working.pre_comp_used_total
puts">==>>>>>>>monthly_working.compensatory_used_total : #{monthly_working.compensatory_used_total}"
      
      monthly_working.save!
    }
  end

end
