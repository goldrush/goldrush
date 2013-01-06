# -*- encoding: utf-8 -*-
class RouteExpenseDetailController < ApplicationController

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @user = User.find(params[:id], :conditions => "deleted = 0 ")
    @route_expense_detail_pages, @route_expense_details = paginate(:route_expense_details, :per_page => SysConfig.get_per_page_count, :include => [ :route_expense ], :conditions => ["route_expenses.user_id = ? and route_expenses.deleted = 0 and route_expense_details.deleted = 0", params[:id]]) 
  end

  def show
    @route_expense_detail = RouteExpenseDetail.find(params[:id], :conditions => "deleted = 0 ")
    @user = User.find(@route_expense_detail.route_expense.user_id , :conditions => "deleted = 0 ")
  end

  def new
    @route_expense_detail = RouteExpenseDetail.new
    @route_expense_detail.monthly_amount = 0
    @user = User.find(params[:id], :conditions => "deleted = 0 ")
  end

  def create
    ActiveRecord::Base::transaction() do
      @route_expense_detail = RouteExpenseDetail.new(params[:route_expense_detail])
      user = User.find(params[:user][:id], :conditions => "deleted = 0 ")
      if user.route_expense
        @route_expense_detail.route_expense_id = user.route_expense.id
      else
        @route_expense = RouteExpense.new
        @route_expense.user_id = user.id
        set_user_column @route_expense
        @route_expense.save!
        @route_expense_detail.route_expense_id = @route_expense.id
      end

      set_user_column @route_expense_detail
      @route_expense_detail.save!
      @route_expense_detail.route_expense.total_amount = @route_expense_detail.route_expense.total_amount.to_i + @route_expense_detail.monthly_amount
      set_user_column @route_expense_detail.route_expense
      @route_expense_detail.route_expense.save!
      
      flash[:notice] = '交通機関情報を作成しました'
      redirect_to :action => 'list', :id => user
    end
  rescue ActiveRecord::RecordInvalid
    @user = User.find(params[:user][:id], :conditions => "deleted = 0 ")
    render :action => 'new'
  end

  def edit
    @route_expense_detail = RouteExpenseDetail.find(params[:id], :conditions => "deleted = 0 ")
    @user = User.find(@route_expense_detail.route_expense.user_id , :conditions => "deleted = 0 ")
    
  end

  def update
    ActiveRecord::Base::transaction() do
      @route_expense_detail = RouteExpenseDetail.find(params[:id], :conditions => "deleted = 0 ")
      @route_expense_detail.attributes = params[:route_expense_detail] 
      set_user_column @route_expense_detail
      @route_expense_detail.save!
      @route_expense_detail.route_expense.total_amount = @route_expense_detail.route_expense.total_amount - params[:template_amount].to_i + @route_expense_detail.monthly_amount
      set_user_column @route_expense_detail.route_expense
      @route_expense_detail.route_expense.save!
      flash[:notice] = '交通機関情報を更新しました'
      redirect_to :action => 'show', :id => @route_expense_detail
    end
  rescue ActiveRecord::RecordInvalid
    @user = User.find(@route_expense_detail.route_expense.user_id , :conditions => "deleted = 0 ")
    render :action => 'edit'
  end

  def destroy
    ActiveRecord::Base::transaction() do
      @route_expense_detail = RouteExpenseDetail.find(params[:id], :conditions => "deleted = 0 ")
      @route_expense_detail.route_expense.total_amount = @route_expense_detail.route_expense.total_amount - @route_expense_detail.monthly_amount
      set_user_column @route_expense_detail.route_expense
      @route_expense_detail.route_expense.save!

      @route_expense_detail.deleted = 9
      set_user_column @route_expense_detail
      @route_expense_detail.save!
      redirect_to(params[:back_to] || {:action => 'list', :id => @route_expense_detail.route_expense.user})
      #redirect_to :action => 'show', :id => @route_expense_detail.route_expense
    end
  end
end
