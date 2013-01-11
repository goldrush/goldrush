# -*- encoding: utf-8 -*-
require 'application_util'
class PaymentPerMonth < ActiveRecord::Base
  include AutoTypeName
  include ApplicationUtil

  has_many :expense_details, :conditions => "deleted = 0 and credit_card_flg = 0 and payment_per_case_id is null", :order => "buy_date"
  has_many :all_expense_details, :class_name => "ExpenseDetail", :conditions => "deleted = 0", :order => "buy_date"
  has_many :card_expense_details, :class_name => "ExpenseDetail", :conditions => "deleted = 0 and credit_card_flg = 1", :order => "buy_date"
  has_many :payment_per_cases, :conditions => "deleted = 0"
  belongs_to :user
  belongs_to :base_application
  belongs_to :base_month

  def PaymentPerMonth.get_payment_per_month(base_month, user_id)
    unless payment_per_month = PaymentPerMonth.find(:first, :conditions => ["base_month_id = ? and deleted = 0 and user_id = ?", base_month.id, user_id])
      payment_per_month = PaymentPerMonth.new
      payment_per_month.base_month_id = base_month.id
      payment_per_month.cutoff_status_type = 'open'
      payment_per_month.cutoff_period = base_month.end_date.strftime('%Y%m')
      payment_per_month.cutoff_start_date = base_month.start_date
      payment_per_month.cutoff_end_date = base_month.end_date
      payment_per_month.user_id = user_id
    end
    return payment_per_month
  end

  def cutoff_period_format
    cutoff_period[0..3] + '/' + cutoff_period[4..5]
  end

  def cutoff?
    cutoff_status_type == 'closed'
  end

  def plan_paid_date
    today = self.cutoff_end_date.to_date
    lastday = Date.new(today.year,today.month,-1)
    plan_paid_date = lastday
    7.times{|i|
      if ![0,6].include?((lastday - i).wday)
        bd = BaseDate.find_by_calendar_date((lastday - i), :conditions => "deleted = 0")
        next if bd.holiday_flg == 1 if bd
        plan_paid_date = (lastday - i)
        break
      end
    }
    return plan_paid_date
  end

  def PaymentPerMonth.get_target_month(target_user_id)
    ppm = find(:first, :conditions => ["deleted = 0 and user_id = ? and cutoff_status_type in ('closed', 'waiting')", target_user_id], :order => "cutoff_start_date desc")
    find(:first, :conditions => ["deleted = 0 and user_id = ? and cutoff_start_date > ?", target_user_id, ppm.cutoff_start_date], :order => "cutoff_start_date") if ppm
  end
end

