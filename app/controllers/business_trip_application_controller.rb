# -*- encoding: utf-8 -*-
require 'sales_person_logic'
class BusinessTripApplicationController < ApplicationController
  include SalesPersonLogic

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @calendar = true
    @approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = ? and deleted = 0 ", current_user.id, 'business_trip_approval', 1], :order => 'approver_id')
    @business_trip_application_pages, @business_trip_applications = paginate(:business_trip_applications, :per_page => 30, :conditions => ["user_id = ? and deleted = 0 ", current_user.id], :order => 'application_date DESC, id DESC ')
  end

  def list_by_approver
    @approval_authorities = ApprovalAuthority.find(:all, :conditions => ["approver_type = ? and active_flg = ? and deleted = 0", 'business_trip_approval', 1])
    @business_trip_application_pages, @business_trip_applications = paginate(:business_trip_applications, :per_page => 30, :include => [ :application_approvals ], :conditions => ["application_approvals.approver_id = ? and business_trip_applications.deleted = 0", current_user.id], :order => 'application_date DESC')
    #render :action => 'list'
  end
  
  def do_search
    @calendar = true
    parseTimes(params)
    if params[:date_from] == "" && params[:date_to] == ""
      start_date = Date.today - 2.month
      end_date = Date.today + 1.month
    elsif params[:date_from] != "" && params[:date_to] == ""
      start_date = params[:date_from].to_date
      end_date = start_date
    elsif params[:date_from] == "" && params[:date_to] != ""
      end_date = params[:date_to].to_date
      start_date = end_date
    else
      start_date = params[:date_from].to_date
      end_date = params[:date_to].to_date
    end
    
    @approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = ? and deleted = 0 ", current_user.id, 'business_trip_approval', 1], :order => 'approver_id')
    @business_trip_application_pages, @business_trip_applications = paginate(:business_trip_applications, :per_page => 30, :conditions => ["user_id = ? and deleted = 0 and application_date between ? and ?", current_user.id, start_date, end_date])
    render :action => 'list'
  end
  
  def show
    @business_trip_application = BusinessTripApplication.find(params[:id], :conditions => "deleted = 0 ")
  end
  
  def show_by_user
    @application_approval = ApplicationApproval.find(params[:app_approval_id], :conditions => "deleted = 0 ")
    @business_trip_application = BusinessTripApplication.find(params[:id], :conditions => "deleted = 0 ")

    render :action => 'show'
  end

  def new
    @calendar = true
    @business_trip_application = BusinessTripApplication.new
    @business_trip_application.application_date = Time.now
    @business_trip_application.start_date = Date.today.to_date
    @business_trip_application.end_date = Date.today.to_date
  end

  def create
    parseTimes(params)
   
    @business_trip_application = BusinessTripApplication.new(params[:business_trip_application])
    @business_trip_application.user_id = current_user.id
    
    if @business_trip_application.start_date.blank?
      raise ValidationAbort.new("開始日を入力してください")
    end
    if @business_trip_application.end_date.blank?
      raise ValidationAbort.new("終了日を入力してください")
    end
    
    #automatically day total of business trip
    daily_workings = @business_trip_application.get_all_daily_workings
    
    @business_trip_application.day_total = daily_workings.size
    if @business_trip_application.day_total == 0
      raise ValidationAbort.new("対象日が選択されていません。日付の指定を変更するか、勤務表の初期化を行ってください")
    end
    
    if @business_trip_application.book_no.to_s.length != 8
      raise ValidationAbort.new('8桁で受注Noを入力してください')
    end

    if !BusinessTripApplication.get_business_trip_applications(@business_trip_application.user_id, @business_trip_application.start_date, @business_trip_application.end_date).empty?
      raise ValidationAbort.new("すでに出張申請されています")
    end

    if @business_trip_application.monthly_working_applicated?
      raise ValidationAbort.new('対象月は、すでに勤務表が提出されています')
    end

    # 全日出勤、午前休、午後休、休日出勤以外の勤怠はオプションをつけることができない
    HolidayApplication.get_holiday_applications(@business_trip_application.user_id, @business_trip_application.start_date, @business_trip_application.end_date).each do |x|
      if !DailyWorking.regular_working_type.include?(x.working_type)
        raise ValidationAbort.new("すでに#{x.working_type_name}申請されています")
      end
    end
    daily_workings.each do |daily_working|
      if !daily_working.action_type_blank? && !DailyWorking.regular_working_type.include?(daily_working.working_type)
        raise ValidationAbort.new("#{daily_working.working_type_name}の日には、申請できません")
      end
    end

    #出張申請での全て承認者を取る。
    approval_authorities = ApprovalAuthority.find(:all, :conditions => ["user_id = ? and approver_type = ? and active_flg = 1 and deleted = 0", @business_trip_application.user_id, 'business_trip_xxx'])

    # by SalesPersonLogic
    check_sales_person(@business_trip_application, approval_authorities)

    if approval_authorities.empty?
      raise ValidationAbort.new('承認者が一人も登録されていません。承認権限設定をしてください')
    end
    
    ActiveRecord::Base.transaction do
      # もし、作業日が確定していた場合、未確定に戻す
      daily_workings.each do |daily_working|
        if daily_working.action_type == 'fixed'
          daily_working.action_type = 'updated'
          set_user_column daily_working
          daily_working.save!
        end
      end

      base_application = BaseApplication.new
      base_application.user_id = current_user.id
      base_application.application_type = 'business_trip_app'
      base_application.approval_status_type = 'entry'
      base_application.application_date = @business_trip_application.application_date
      set_user_column base_application
      base_application.save!

      @business_trip_application.base_application_id = base_application.id
      set_user_column @business_trip_application
      @business_trip_application.save!
      #申請に承認者を設定
      count = 0
      for approval_authority in approval_authorities
        count = count + 1
        application_approval = ApplicationApproval.new
        application_approval.user_id = approval_authority.user_id
        application_approval.base_application_id = base_application.id
        application_approval.application_type = 'business_trip_app'
        application_approval.application_date = @business_trip_application.application_date
        application_approval.approver_id = approval_authority.approver_id
        application_approval.approval_status_type = 'entry'
        application_approval.approval_order = count
        set_user_column application_approval
        application_approval.save!
      end
    end

    flash[:notice] = "出張申請情報を作成しました。"
    redirect_to :action => 'show', :id => @business_trip_application
  rescue ValidationAbort
    flash[:warning] = $!
    @calendar = true
    render :action => 'new'
  rescue ActiveRecord::RecordInvalid
    @calendar = true
    render :action => 'new'
  end

  def edit
    @calendar = true
    @business_trip_application = BusinessTripApplication.find(params[:id], :conditions => "deleted = 0 ")
  end

  def update
    parseTimes(params)
    @business_trip_application = BusinessTripApplication.find(params[:id], :conditions => "deleted = 0 ")
    @business_trip_application.attributes = params[:business_trip_application] 
    
    if @business_trip_application.book_no.blank?
      flash[:err] = '受注Noを入力してください'
      render :action => 'edit'
      return
    end
    if @business_trip_application.book_no.to_s.length != 8
      flash[:err] = '8桁で受注Noを入力してください'
      render :action => 'edit'
      return
    end

    ActiveRecord::Base.transaction do
      #automatically day total of business trip
      daily_workings = @business_trip_application.get_all_daily_workings
      @business_trip_application.day_total = daily_workings.size
      if @business_trip_application.day_total == 0
        raise ValidationAbort.new("対象日が選択されていません。日付の指定を変更するか、勤務表の初期化を行ってください")
      end
      set_user_column @business_trip_application
      @business_trip_application.save!
    end
    flash[:notice] = "出張申請情報を変更しました。"
    redirect_to(params[:back_to] || {:action => 'show', :id => @business_trip_application})
  rescue ActiveRecord::RecordInvalid
    @calendar = true
    render :action => 'edit'
  end

  def destroy
    business_trip_application = BusinessTripApplication.find(params[:id], :conditions => "deleted = 0 ")
    business_trip_application.deleted = 9
    set_user_column business_trip_application
    business_trip_application.save!
    redirect_to :action => 'list'
  end
end
