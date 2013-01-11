# -*- encoding: utf-8 -*-
require 'application_util'
class WeeklyReport < ActiveRecord::Base
  include ApplicationUtil

  has_many :weekly_report_details, :conditions => "weekly_report_details.deleted = 0"
  has_many :comments, :conditions => "comments.deleted = 0"
  belongs_to :user
  belongs_to :base_month
  belongs_to :base_application, :conditions => "base_applications.deleted = 0 and base_applications.approval_status_type != 'canceled'"

  validates_length_of       :content, :maximum => 4000, :allow_blank => true
  
  # BaseDateを基準にDailyWorkingを取得し、無ければ捏造する
  def get_daily_workings
    daily_workings = []
    base_dates = BaseDate.find(:all, :conditions => ["deleted = 0 and calendar_date between ? and ?", start_date.to_date, end_date.to_date], :order => "calendar_date")
    base_dates.each do |base_date|
      unless daily_working = DailyWorking.find(:first, :conditions => ["deleted = 0 and base_date_id = ? and user_id = ?", base_date.id, user_id])
        daily_working = DailyWorking.new
        daily_working.user_id = user.id
        daily_working.base_date_id = base_date.id
        daily_working.monthly_working_id = nil
        daily_working.working_date = base_date.calendar_date.to_date
        daily_working.action_type = 'blank'
        if [0, 6].include?(base_date.day_of_week) or base_date.holiday_flg == 1
          daily_working.holiday_flg = 1
        end
        daily_working.summary = "日報が未初期化です"
      end
      daily_workings << daily_working
    end
    return daily_workings
  end

  def want_application?
    !self.empty_contents? && self.base_application.blank?
  end

  def empty_contents?
    client.blank? && content.blank? && relative_staff.blank?
  end

end
