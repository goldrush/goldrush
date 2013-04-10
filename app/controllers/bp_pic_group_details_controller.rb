# -*- encoding: utf-8 -*-
class BpPicGroupDetailsController < ApplicationController
  # GET /bp_pic_group_details
  # GET /bp_pic_group_details.json
  def index
    @bp_pic_group_details = BpPicGroupDetail.page(params[:page]).per(50)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @bp_pic_group_details }
    end
  end

  # GET /bp_pic_group_details/1
  # GET /bp_pic_group_details/1.json
  def show
    @bp_pic_group_detail = BpPicGroupDetail.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @bp_pic_group_detail }
    end
  end

  # GET /bp_pic_group_details/new
  # GET /bp_pic_group_details/new.json
  def new
    @bp_pic_group_detail = BpPicGroupDetail.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @bp_pic_group_detail }
    end
  end

  # GET /bp_pic_group_details/1/edit
  def edit
    @bp_pic_group_detail = BpPicGroupDetail.find(params[:id])
  end

  # POST /bp_pic_group_details
  # POST /bp_pic_group_details.json
  def create
    @bp_pic_group_detail = BpPicGroupDetail.new(params[:bp_pic_group_detail])

    respond_to do |format|
      begin
        @bp_pic_group_detail.save!
        format.html { redirect_to @bp_pic_group_detail, notice: 'Bp pic group detail was successfully created.' }
        format.json { render json: @bp_pic_group_detail, status: :created, location: @bp_pic_group_detail }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @bp_pic_group_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /bp_pic_group_details/1
  # PUT /bp_pic_group_details/1.json
  def update
    @bp_pic_group_detail = BpPicGroupDetail.find(params[:id])

    respond_to do |format|
      begin
        @bp_pic_group_detail.update_attributes!(params[:bp_pic_group_detail])
        format.html { redirect_to @bp_pic_group_detail, notice: 'Bp pic group detail was successfully updated.' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @bp_pic_group_detail.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bp_pic_group_details/1
  # DELETE /bp_pic_group_details/1.json
  def destroy
    
    @bp_pic_group_detail = BpPicGroupDetail.find(params[:id])
    @bp_pic_group_detail.deleted = 9
    @bp_pic_group_detail.deleted_at = Time.now
    set_user_column @bp_pic_group_detail
    @bp_pic_group_detail.save!
    
    respond_to do |format|
      format.html { redirect_to url_for(:controller => :bp_pic_groups, :action => :show, :id => @bp_pic_group_detail.bp_pic_group_id), notice: 'Bp pic group detail was successfully deleted.' }
    end

  end

end