# -*- encoding: utf-8 -*-
require 'application_util'
class OtherApplication < ActiveRecord::Base
  include AutoTypeName
  include DateTimeUtil
  include ApplicationUtil
  
  belongs_to :user
  belongs_to :base_application
  
  validates_length_of :reason, :maximum=>4000, :allow_blank => true
  validates_length_of :content, :maximum=>4000, :allow_blank => true

  def OtherApplication.get_other_applications(user_id, start_date, end_date)
    OtherApplication.find(:all, :include =>[:base_application], :conditions => [
     "other_applications.deleted = 0 and other_applications.user_id = :user_id and target_date >= :start_date and target_date <= :end_date and base_applications.approval_status_type != 'canceled'",
      {:user_id => user_id, :start_date => start_date.to_date, :end_date => end_date.to_date}], :order => "other_applications.application_date")
  end

  # ['over_time_app','go_directly_app','back_directly_app','come_lately_app','leave_early_app']

  # 遅刻早退直行直帰をLack(欠けた)と定義してみた
  def lack_application?
    ['go_directly_app','back_directly_app','come_lately_app','leave_early_app'].include?(self.working_option_type)
  end

  def read_only_start_time?
    ['back_directly_app','leave_early_app'].include?(self.working_option_type)
  end

  def read_only_end_time?
    ['go_directly_app','come_lately_app'].include?(self.working_option_type)
  end

  def start_time_format
    calHourMinuteFormat(self.start_time) if self.start_time
  end

  def end_time_format
    calHourMinuteFormat(self.end_time) if self.end_time
  end

  def set_time_str(param)
    self.start_time =  hourminstr_to_sec(param.delete(:start_time)) unless param[:start_time].blank?
    self.end_time = hourminstr_to_sec(param.delete(:end_time)) unless param[:end_time].blank?
  end

  def get_daily_working
    DailyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and working_date = ?",self.user_id, self.target_date.to_date])
  end

  def monthly_working_applicated?
    mw = MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and start_date <= ? and end_date >= ? and base_application_id is not null", self.user_id, self.target_date.to_date, self.target_date.to_date])
    mw && mw.base_application #.approval_status_type == 'fixed'
  end

end
