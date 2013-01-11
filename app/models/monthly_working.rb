# -*- encoding: utf-8 -*-
require 'application_util'
class MonthlyWorking < ActiveRecord::Base
  include AutoTypeName
  include DateTimeUtil
  include ApplicationUtil
  
  attr_accessor :working_type_counts
  attr_accessor :holiday_applications
  attr_accessor :other_applications
  attr_accessor :business_trip_applications

  has_many :daily_workings, :order => 'working_date'
  belongs_to :user
  belongs_to :base_month
#  has_many :application_approvals
  belongs_to :base_application
  
  validates_numericality_of :labor_day_total

  # vacationで計算用に使う便利メソッド。画面から呼んではいけない
  def remain_compensatory_hour_total
    self.compensatory_hour_total.to_i - self.compensatory_used_total.to_i
  end

  def count_working_type
    self.working_type_counts = Hash.new
    self.daily_workings.each{|work|
      self.working_type_counts[work.working_type] ||= 0
      self.working_type_counts[work.working_type] += 1 if work.fixed?
    }
    return self.working_type_counts
  end

  def get_working_type_counts(array_of_working_type)
    count = 0
    array_of_working_type.each{|working_type|
      count += self.working_type_counts[working_type].to_i
    }
    return count
  end
  def come_lately_count
    count = 0
    self.daily_workings.each{|work|
      #count += 1 if work.come_lately_flg == 1 && work.fixed?
      count += 1 if work.come_lately_flg == 1 && work.delayed_cancel_flg == 0 && work.fixed?
    }
    return count
  end
  
  def leave_early_count
    count = 0
    self.daily_workings.each{|work|
      count += 1 if work.leave_early_flg == 1 && work.fixed?
    }
    return count
  end
  
  def over_time_count
    count = 0
    self.daily_workings.each{|work|
      count += 1 if work.over_time.to_i > 0 && work.fixed?
    }
    return count
  end
  
  def business_trip_count
    count = 0
    self.daily_workings.each{|work|
      count += 1 if work.business_trip_flg == 1 && work.fixed?
    }
    return count
  end
  
  def taxi_count
    count = 0
    self.daily_workings.each{|work|
      count += 1 if work.taxi_flg == 1 && work.fixed?
    }
    return count
  end
  
  def real_working_second_count
    count = 0
    self.daily_workings.each{|work|
      count += work.hour_total.to_i if work.count_hour_total? && work.fixed?
    }
    return count
  end

  def real_working_hour_count
    self.real_working_second_count.to_f / (60 * 60)
  end
  
  def real_working_hour_format
    DateTimeUtil.calHourMinuteFormatJa(self.real_working_second_count)
  end
  
  def get_labor_working_hour_count
    if self.labor_day_total == nil
      return 0
    else
      user = User.find(self.user_id)
      return self.labor_day_total * user.employee.regular_working_hour if user
    end
  end
  
  def total_negative_hour
    h1 = self.get_labor_working_hour_count
    sec1 = h1 * 3600
    sec2 = self.real_working_second_count
    sec = (sec2 - sec1)
    return sec
  end
  
  def format_hour_minute(sec)
    return DateTimeUtil.calHourMinuteFormat(sec)
  end
  
  def total_latearly_count
    lately_count = self.come_lately_count
    early_count = self.leave_early_count
    return (lately_count + early_count)
  end
  
  def total_vacation_count
    full_vacation = self.get_working_type_counts(['vacation_dayoff'])
    half_vacation = self.get_working_type_counts(['only_AM_working','only_PM_working'])
    return (full_vacation + (half_vacation * 0.5))
  end

  def other_application_type?(type)
    ['over_time_app','go_directly_app','back_directly_app','come_lately_app','leave_early_app']
  end

  # 申請データを一括でもって来る
  def init_approval_list(force = false)
    # user_idが同じで、月初 >= 開始日, 月末 <= 開始日, 月初 >= 終了日, 月末 >= 終了日を満たすもの
    self.holiday_applications = HolidayApplication.get_holiday_applications(self.user_id, self.start_date, self.end_date) if self.holiday_applications.blank? or force
    self.other_applications = OtherApplication.get_other_applications(self.user_id, self.start_date, self.end_date) if self.other_applications.blank? or force
    self.business_trip_applications = BusinessTripApplication.get_business_trip_applications(self.user_id, self.start_date, self.end_date) if self.business_trip_applications.blank? or force
  end

  # 休暇申請の取得
  def holiday_application_by_date(date)
    date = date.to_date
    holiday_application = nil
    self.holiday_applications.each{|app|
      if app.start_date.to_date <= date and app.end_date.to_date >= date
        holiday_application = app
      end
    }
    return holiday_application
  end
  
  # 日別の他勤怠申請の取得
  def other_applications_by_date(date)
    self.other_applications.collect{|app|
      app if app.target_date.to_date == date.to_date
    }.compact
  end

  # 出張申請されているか?
  def business_trip_application_by_date(date)
    date = date.to_date
    self.business_trip_applications.each{|app|
      return app if app.start_date.to_date <= date and app.end_date.to_date >= date
    }
    return nil
  end

  # 残業申請されているか?
  def over_time_application_by_date(date)
    get_application_by_date_type(date, 'over_time_app')
  end

  # 遅刻申請されているか?
  def come_lately_application_by_date(date)
    get_application_by_date_type(date, 'come_lately_app')
  end

  # 早退申請されているか?
  def leave_early_application_by_date(date)
    get_application_by_date_type(date, 'leave_early_app')
  end

  def get_application_by_date_type(date,type)
    date = date.to_date
    self.other_applications.each{|app|
      return app if app.target_date.to_date == date.to_date and app.working_option_type == type
    }
    return nil
  end
  
  def get_color_approval_status_type_set_lack_app_by_date(date)
    approval_status_type = nil
    self.other_applications.each{|app|
      if app.target_date.to_date == date.to_date and app.lack_application? 
        return get_color_by_approval_status_type(app.base_application.approval_status_type) if app.base_application.approval_status_type == 'reject'
        if app.base_application.approval_status_type != 'reject' and approval_status_type == 'entry'
          approval_status_type = 'entry'
        else
          approval_status_type = app.base_application.approval_status_type
        end
      end
    }
    return get_color_by_approval_status_type(approval_status_type)
  end

  def no_input_data_count
    count = 0
    self.daily_workings.each{|work|
      # 就業日後の平日で日報未登録のものをカウント
      count += 1 if !work.holiday? && work.action_type_blank? && work.working_date >= work.entry_date
    }
    return count
  end

  def no_input_data_count_holiday
    count = 0
    self.daily_workings.each{|work|
      # 就業日後の休日に休日出勤申請が出ているのに日報未登録のものをカウント
      count += 1 if work.holiday? && work.action_type_blank? && HolidayApplication.find(:first, :include => [:base_application], :conditions => ["holiday_applications.deleted = 0 and holiday_applications.user_id = ? and holiday_applications.start_date = ? and base_applications.approval_status_type != 'canceled'", self.user_id, work.working_date])
# work.holiday? && 
# work.action_type_blank? && 
# HolidayApplication.find(
#   :first, 
#   :include => [:base_application], 
#   :conditions => ["
#       holiday_applications.deleted = 0 and 
#       holiday_applications.user_id = ? and      # self.user_id
#       holiday_applications.start_date = ? and   # work.working_date
#       base_applications.approval_status_type != 'canceled'
#   ", self.user_id, work.working_date])
    }
    return count
  end


  def entry_holiday_app_count
    count = 0
    self.holiday_applications.each{|app|
      if ['entry','retry','approved','reject'].include?(app.base_application.approval_status_type)
        count += 1
      end
    }
    return count
  end

  def entry_other_app_count
    count = 0
    self.other_applications.each{|app|
      if ['entry','retry','approved','reject'].include?(app.base_application.approval_status_type)
        count += 1
      end
    }
    return count
  end

  def entry_business_trip_app_count
    count = 0
    self.business_trip_applications.each{|app|
      if ['entry','retry','approved','reject'].include?(app.base_application.approval_status_type)
        count += 1
      end
    }
    return count
  end

  def entry_working_app_count
    return (entry_holiday_app_count + entry_other_app_count + entry_business_trip_app_count)
    #return (entry_holiday_app_count + entry_other_app_count)
  end

  def calc_compensatory_dayoff_count
    DailyWorking.count(:conditions => ["deleted = 0 and monthly_working_id = ? and working_type = 'compensatory_dayoff'", self.id])
  end

  def resist(vacation, over_start_date)
    # 実績保持の際に翌月以降分を抜く
puts">>>> over_start_date         : #{over_start_date}"
puts">>>> over_start_date.to_date : #{over_start_date.to_date}"
puts"-------------------------------------------------------------------"
    
    over_used_total = 0
    over_summer_dayoff_total = 0
    over_life_plan_dayoff_total = 0
    over_compensatory_hour_total = 0
    over_compensatory_used_total = 0
    
    regular_working_hour = (vacation.user.employee.regular_working_hour * 60 * 60).to_i
    
puts">>>> regular_working_hour : #{regular_working_hour}"
puts"-------------------------------------------------------------------"
    
    over_days = DailyWorking.find(:all, :conditions => ["deleted = 0 and user_id = ? and working_date >= ? and action_type = 'fixed'", vacation.user, over_start_date.to_date])
    over_days.each{|over_day|
      case over_day.working_type
        when 'vacation_dayoff'
          over_used_total += 1
        when 'only_AM_working'
          over_used_total += 0.5
        when 'only_PM_working'
          over_used_total += 0.5
        when 'summer_dayoff'
          over_summer_dayoff_total += 1
        when 'life_plan_dayoff'
          over_life_plan_dayoff_total += 1
        when 'on_holiday_working'
          over_compensatory_hour_total += over_day.hour_total.to_i
        when 'compensatory_dayoff'
          over_compensatory_used_total += regular_working_hour.to_i
      end
    }
    
puts">>>>>>>>>>>>>>> over_used_total : #{over_used_total}"
puts">>>>>> over_summer_dayoff_total : #{over_summer_dayoff_total}"
puts">>> over_life_plan_dayoff_total : #{over_life_plan_dayoff_total}"
puts">> over_compensatory_hour_total : #{over_compensatory_hour_total}"
puts">> over_compensatory_used_total : #{over_compensatory_used_total}"
    
    self.remain_total = vacation.remain_total + over_used_total
    self.compensatory_remain_total = vacation.compensatory_remain_total + over_compensatory_used_total - over_compensatory_hour_total
    self.cutoff_day_total = vacation.calced_cutoff_day_total_format + over_used_total
    self.cutoff_compensatory_hour_total = ((vacation.cutoff_compensatory_hour_total + over_compensatory_used_total) < 0 ? 0 : vacation.cutoff_compensatory_hour_total + over_compensatory_used_total)
    self.summer_vacation_remain_total = vacation.summer_vacation_remain_total(self.end_date) + over_summer_dayoff_total
    self.life_plan_remain_total = vacation.life_plan_remain_total + over_life_plan_dayoff_total
    self.hold_flg = 1
    self.save!
  end

  def resist_delete
    self.remain_total = 0
    self.compensatory_remain_total = 0
    self.cutoff_day_total = 0
    self.cutoff_compensatory_hour_total = 0
    self.summer_vacation_remain_total = 0
    self.life_plan_remain_total = 0
    self.hold_flg = 0
    self.save!
  end


# 最後の月報しか解除できないようにする判定
# 対象月報がMonthlyWorkingのBaseApplication付きの一番でかいやつなら、最後の月報。
# と見せかけて、取消後はbase_application_id消すので確実では無い！
# 一旦申請されたものについてはBaseApplicationが作られるはずなので、BaseApplicationを見に行って、それよりＩＤのでかいのがなければ最後の月報。
# 早い話、いちばんでかいbase_application(deletedは問わない)のひもづけられたデータが対象月ならＯＫで、null回避に注意。
  def last_mw?
    last_base_application = BaseApplication.find(:first, :joins => "left join monthly_workings on monthly_workings.base_application_id = base_applications.id", :conditions => ["base_applications.user_id = ? and base_applications.application_type = 'monthly_working_app'", self.user_id], :order => "base_applications.id desc")
     if (last_base_application.monthly_working && last_base_application.monthly_working.id == self.id)
      return true
    else
      return false
    end
  end

# 先月の月報が申請されているかどうかの判定
# 対象MWのstart_dateの次に小さいstart_dateのMWにBA_idがあればＯＫ（最初の月報ならＯＫ）
  def last_mw_applicated?
    last_monthly_working = MonthlyWorking.find(:first, :include => [:daily_workings], :conditions => ["monthly_workings.user_id = ? and monthly_workings.start_date < ? and daily_workings.working_type != 'suspension1_dayoff' and daily_workings.working_type != 'suspension2_dayoff'", self.user_id, self.start_date], :order => "monthly_workings.start_date desc")
    if !last_monthly_working || last_monthly_working.base_application
      return true
    else
      return false
    end
  end

# 先月の月報が承認済かどうかの判定
# 対象MWのstart_dateの次に小さいstart_dateのMWにひもづけられたBAのステータスがfixedならＯＫ（最初の月報ならＯＫ）
  def last_mw_fixed?
#puts"===========================>>> start_date : #{self.start_date}"
    last_monthly_working = MonthlyWorking.find(:first, :include => "base_application", :conditions => ["base_applications.deleted = 0 and monthly_workings.user_id = ? and monthly_workings.start_date < ?", self.user_id, self.start_date], :order => "monthly_workings.start_date desc")
#puts"===========================> #{last_monthly_working.id}"
    if !last_monthly_working || last_monthly_working.base_application.approval_status_type == 'fixed'
      return true
    else
      return false
    end
  end

# 月報が承認済かどうかの判定
  def fixed?
    if self.base_application
      return true if self.base_application.approval_status_type == 'fixed'
    end
    return false
  end

end
