# -*- encoding: utf-8 -*-
require 'application_util'
class BusinessTripApplication < ActiveRecord::Base
  include AutoTypeName
  include ApplicationUtil

  attr_accessor :sales_person

  belongs_to :user
  has_many :expense_details
  belongs_to :base_application
  
  validates_length_of :book_no, :maximum=>40, :allow_blank => true
  validates_length_of :reason, :maximum=>4000, :allow_blank => true
  validates_length_of :content, :maximum=>4000, :allow_blank => true
  validates_length_of :location, :maximum=>4000, :allow_blank => true
  
  # 申請の対象となる作業日を取得する
  def get_all_working_days
    daily_workings = DailyWorking.get_all_working_days(self.user_id, self.start_date, self.end_date)
  end

  def get_all_daily_workings
    daily_workings = DailyWorking.get_all_working_days(self.user_id, self.start_date, self.end_date)
  end

  def BusinessTripApplication.get_business_trip_applications(user_id, start_date, end_date)
    BusinessTripApplication.find(:all, :include =>[:base_application], :conditions => [
      "business_trip_applications.deleted = 0 and business_trip_applications.user_id = :user_id and ((start_date >= :start_date and start_date <= :end_date) or (end_date >= :start_date and end_date <= :end_date) or (:start_date >= start_date and :start_date <= end_date) or (:end_date >= start_date and :end_date <= end_date)) and base_applications.approval_status_type != 'canceled'",
      {:user_id => user_id, :start_date => start_date.to_date, :end_date => end_date.to_date}], :order => "business_trip_applications.application_date")
  end

  def monthly_working_applicated?
    mw = MonthlyWorking.find(:first, :conditions => ["deleted = 0 and user_id = ? and start_date <= ? and end_date >= ? and base_application_id is not null", self.user_id, self.start_date.to_date, self.start_date.to_date])
#    mw && mw.base_application.approval_status_type == 'fixed'
    mw && mw.base_application #.approval_status_type == 'fixed'
  end

  def sales_person_name
    x = Employee.find(:first, :conditions => ["user_id = ?", sales_person_id])
    x && x.employee_name
  end

end
