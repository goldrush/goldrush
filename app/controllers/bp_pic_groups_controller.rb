# -*- encoding: utf-8 -*-
class BpPicGroupsController < ApplicationController
  # GET /bp_pic_groups
  # GET /bp_pic_groups.json
  def index
    @bp_pic_groups = BpPicGroup.page(params[:page]).per(50)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @bp_pic_groups }
    end
  end

  # GET /bp_pic_groups/1
  # GET /bp_pic_groups/1.json
  def show
    @title = params[:group_name]
    @bp_pic_names = []
    @bp_pic_group = BpPicGroup.find(params[:id])
    @bp_pic_group_details = BpPicGroupDetail.find(:all, :conditions => ["deleted = 0 and bp_pic_group_id = ? ", params[:id]])
    @bp_pic_group_details.each do |bp_pic_group_detail|
      bp_pic = BpPic.find(bp_pic_group_detail.bp_pic_id)
      business_partner = BusinessPartner.find(bp_pic.business_partner_id)
      @bp_pic_names.push([business_partner.business_partner_name, bp_pic.bp_pic_name, business_partner.id, bp_pic.id])
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @bp_pic_group }
    end
  end

  # GET /bp_pic_groups/new
  # GET /bp_pic_groups/new.json
  def new
    @bp_pic_group = BpPicGroup.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @bp_pic_group }
    end
  end

  # GET /bp_pic_groups/1/edit
  def edit
    @bp_pic_group = BpPicGroup.find(params[:id])
  end

  # POST /bp_pic_groups
  # POST /bp_pic_groups.json
  def create
    @bp_pic_group = BpPicGroup.new(params[:bp_pic_group])

    respond_to do |format|
      begin
        @bp_pic_group.save!
        format.html { redirect_to @bp_pic_group, notice: 'Bp pic group was successfully created.' }
        format.json { render json: @bp_pic_group, status: :created, location: @bp_pic_group }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "new" }
        format.json { render json: @bp_pic_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /bp_pic_groups/1
  # PUT /bp_pic_groups/1.json
  def update
    @bp_pic_group = BpPicGroup.find(params[:id])

    respond_to do |format|
      begin
        @bp_pic_group.update_attributes!(params[:bp_pic_group])
        format.html { redirect_to @bp_pic_group, notice: 'Bp pic group was successfully updated.' }
        format.json { head :no_content }
      rescue ActiveRecord::RecordInvalid
        format.html { render action: "edit" }
        format.json { render json: @bp_pic_group.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bp_pic_groups/1
  # DELETE /bp_pic_groups/1.json
  def destroy
    @bp_pic_group = BpPicGroup.find(params[:id])
    @bp_pic_group.destroy

    respond_to do |format|
      format.html { redirect_to bp_pic_groups_url }
      format.json { head :no_content }
    end
  end
end
