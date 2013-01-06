# -*- encoding: utf-8 -*-
class ApprovalAuthorityController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @approver_type = params[:approver_type]
    @user_employees = User.find(:all, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.resignation_date IS NULL"], :order => 'users.id')
    @user_approvers = User.find(:all, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.approver_flg = ?", 1], :order => 'users.id')
  end

  def set_data
    @user_employee_pages, @user_employees = paginate(:users, :per_page => SysConfig.get_per_page_count, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.resignation_date IS NULL"], :order => 'users.id')
    @user_approvers = User.find(:all, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.approver_flg = ?", 1], :order => 'users.id')
    render :action => 'list'
  end

  def report_xxx
    set_data
  end

  def working_xxx
    set_data
  end

  def business_trip_xxx
    set_data
  end

  def expense_xxx
    set_data
  end

  def show
    @approval_authority = ApprovalAuthority.find(params[:id])
  end

  def new
    @user_approvers = User.find(:all, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.approver_flg = ?", 1], :order => 'users.id')
    @approval_authority = ApprovalAuthority.new
    @approval_authority.user_id = params[:user_id]
    @approval_authority.approver_type = params[:approver_type]
  end

  def create
    if params[:approvers].nil?
      flash[:error] = '承認者対象が選択されていません。'
    else
      params[:approvers].each do |id|
        @approval_authority = ApprovalAuthority.new(params[:approval_authority])
        @approval_authority.approver_type = params[:approver_type]
        @approval_authority.approver_id = id
        @approval_authority.active_flg = 1
        set_user_column @approval_authority
        @approval_authority.save!
      end
    end
    flash[:notice] = 'ApprovalAuthority was successfully created.'
    redirect_to params[:back_to]
  end

  def edit
    @user_approvers = User.find(:all, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.approver_flg = ?", 1], :order => 'users.id')
    @approval_authority = ApprovalAuthority.new
    @approval_authority.user_id = params[:user_id]
    @approval_authority.approver_type = params[:approver_type]
  end

  def update
    user_approvers = User.find(:all, :include => [ :employee ], :conditions => ["users.deleted = 0 and employees.deleted = 0 and employees.approver_flg = ?", 1], :order => 'users.id')
    approval_authority_tmp = ApprovalAuthority.new(params[:approval_authority])
    if params[:approvers].nil?
      #flash[:error] = '承認者対象が選択されていません。'
      for user_approver in user_approvers
        approval_authority = ApprovalAuthority.find(:first, :conditions => ["deleted = 0 and user_id = ? and approver_id = ? and approver_type = ?", approval_authority_tmp.user_id, user_approver.id, params[:approver_type]])
        if approval_authority
          approval_authority.active_flg = 0
          set_user_column approval_authority
          approval_authority.save!
        end
      end
    else
      arrApprovers = Array.new
      for user_approver in user_approvers
        arrApprovers << user_approver.id.to_i
      end
      params[:approvers].each do |id|
        approval_authority = ApprovalAuthority.find(:first, :conditions => ["deleted = 0 and user_id = ? and approver_id = ? and approver_type = ?", approval_authority_tmp.user_id, id, params[:approver_type]])
        if approval_authority
          approval_authority.active_flg = 1
        else
          approval_authority = ApprovalAuthority.new(params[:approval_authority])
          approval_authority.approver_type = params[:approver_type]
          approval_authority.active_flg = 1
          approval_authority.approver_id = id  
        end
        set_user_column approval_authority
        approval_authority.save!
        arrApprovers.delete id.to_i
      end # params
      
      arrApprovers.each do |id|
        approval_authority = ApprovalAuthority.find(:first, :conditions => ["deleted = 0 and user_id = ? and approver_id = ? and approver_type = ?", approval_authority_tmp.user_id, id, params[:approver_type]])
        if approval_authority
          approval_authority.active_flg = 0
          set_user_column approval_authority
          approval_authority.save!
        end 
      end
    end
    
    flash[:notice] = "承認権限を変更しました。"
    redirect_to params[:back_to]
  end

  def destroy
    #ApprovalAuthority.find(params[:id]).destroy
    approval_authority = ApprovalAuthority.find(params[:id], :conditions => "deleted = 0 ")
    approval_authority.deleted = 9
    set_user_column approval_authority
    approval_authority.save!
    redirect_to :action => 'list'
  end
end
