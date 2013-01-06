# -*- encoding: utf-8 -*-
class SysConfig < ActiveRecord::Base
  
  validates_presence_of :config_section
  validates_presence_of :config_key
  validates_length_of :config_section, :maximum=>40
  validates_length_of :config_key, :maximum=>40
  validates_length_of :value1, :maximum=>255, :allow_blank => true
  validates_length_of :value2, :maximum=>255, :allow_blank => true
  validates_length_of :value3, :maximum=>255, :allow_blank => true
  
  @@cache = nil

  def SysConfig.get_config(section, key)
    find(:first, :conditions => ["deleted = 0 and config_section = ? and config_key = ?", section, key])
  end

  def SysConfig.get_value(section, key)
    SysConfig.get_config(section, key).value1
  end

  def SysConfig.init_seq(key, seq)
    x = find(:first, :conditions => ["deleted = 0 and config_section = 'seq' and config_key = ?", key], :lock => true)
    if x
      x.value1 = seq
    else
      x = SysConfig.new
      x.config_section = 'seq'
      x.config_key = key
      x.value1 = seq
    end
    x.created_user = 'init_seq' if x.new_record?
    x.updated_user = 'init_seq'
    x.save!
    return x
  end

  def SysConfig.get_seq_0(key, col)
    seq = SysConfig.get_seq(key)
    sprintf("%.#{col}d", seq)
  end

  def SysConfig.get_seq(key)
    x = find(:first, :conditions => ["deleted = 0 and config_section = 'seq' and config_key = ?", key], :lock => true)
    if x
      x.value1 = x.value1.to_i + 1
    else
      x = SysConfig.new
      x.config_section = 'seq'
      x.config_key = key
      x.value1 = 1
    end
    x.created_user = 'get_seq' if x.new_record?
    x.updated_user = 'get_seq'
    x.save!
    return x.value1.to_i
  end
  
  def SysConfig.load_cache
    @@cache = SysConfig.find(:all)
  end

  def SysConfig.purge_cache
    @@cache = nil
  end

  def self.get_configuration(section, key)
    load_cache unless @@cache
    @@cache.each do |conf|
      break conf if conf.config_section == section and conf.config_key == key
    end
#    SysConfig.find(:first, :conditions => ["deleted = 0 and config_section = ? and config_key = ?", section, key])
  end

  def self.get_vacation_half_year(half_year)
    SysConfig.find(:first, :conditions => ["deleted = 0 and config_section = ? and config_key <= ?", 'vacation_half_year', half_year], :order => 'config_key desc').value1
  end

  def self.get_vacation_month(month)
    get_configuration('vacation_month', month.to_s)
  end

  def self.get_per_page_count
    if c = get_configuration('per_page_count', 'default')
      return c.value1.to_i
    else
      return 40
    end
  end
  
  def self.get_regular_in_time_regular
    get_configuration('regular_in_time', 'regular')
  end
  
  def self.get_regular_in_time_defact
    get_configuration('regular_in_time', 'defact')
  end
  
  def self.get_regular_in_time_pm
    get_configuration('regular_in_time', 'pm')
  end
  
  def self.get_regular_out_time_regular
    get_configuration('regular_out_time', 'regular')
  end
  
  def self.get_regular_out_time_early_am
    get_configuration('regular_out_time', 'early_am')
  end
  
  def self.get_regular_out_time_early_full
    get_configuration('regular_out_time', 'early_full')
  end
  
  def self.get_regular_over_time_meel
    get_configuration('regular_over_time', 'meel')
  end
  
  def self.get_regular_over_time_taxi
    get_configuration('regular_over_time', 'taxi')
  end
  
  def self.get_rest_hour_regular
    get_configuration('rest_hour', 'regular')
  end
  
  def self.get_rest_hour_half
    get_configuration('rest_hour', 'half')
  end
  
  def self.get_hour_total_full
    get_configuration('hour_total', 'full')
  end
  
  def self.get_hour_total_none
    get_configuration('hour_total', 'none')
  end
  
  def self.get_month_start_date
    get_configuration('month_start_date', 'regular')
  end
  
  def self.get_year_start_date
    get_configuration('year_start_date', 'regular')
  end

  def self.get_life_plan_day_max
    get_configuration('life_plan_day_count', 'total_max').value1.to_i
  end

  def self.get_life_plan_behavior_max
    get_configuration('life_plan_day_count', 'behavior_max').value1.to_i
  end
  
  def self.get_day_max
    get_configuration('annual_day_count', 'total_max').value1.to_i
  end
  
  def self.get_before_year_count
    get_configuration('before_year_count', 'regular').value1.to_i
  end

  def self.get_before_month_count
    get_configuration('before_month_count', 'regular').value1.to_i
  end

  def self.get_directory_path(dir_type)
    get_configuration('directory_path', dir_type).value1
  end

  def self.get_summer_vacation_day_total
    get_configuration('summer_vacation', 'day_total')
  end

  def self.get_summer_vacation_start_date
    get_configuration('summer_vacation', 'start_date')
  end

  def self.get_summer_vacation_end_date
    get_configuration('summer_vacation', 'end_date')
  end

  def self.get_calculate_vacation_year
    get_configuration('calculate_vacation', 'year')
  end

  def self.get_color_approval_status_type_entry
    get_configuration('color_approval_status_type', 'entry')
  end
  
  def self.get_color_approval_status_type_approved
    get_configuration('color_approval_status_type', 'approved')
  end
  
  def self.get_color_approval_status_type_reject
    get_configuration('color_approval_status_type', 'reject')
  end
  
end
