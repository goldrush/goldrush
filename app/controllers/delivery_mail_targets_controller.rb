# -*- encoding: utf-8 -*-


class DeliveryMailTargetsController < ApplicationController

  # DELETE /delivery_mail_targets/1
  # DELETE /delivery_mail_targets/1.json
  def destroy
    @delivery_mail_target = DeliveryMailTarget.find(params[:id])
    
    @delivery_mail_target.deleted = 9
    @delivery_mail_target.deleted_at = Time.now
    set_user_column(@delivery_mail_target)
    @delivery_mail_target.save!

    respond_to do |format|
      format.html { redirect_to :controller => :delivery_mails, :action => :show, :id => @delivery_mail_target.delivery_mail_id, notice: 'Delivery mail target was successfully deleted.' }
    end
  end
  
end

