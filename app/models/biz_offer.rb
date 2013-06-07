# -*- encoding: utf-8 -*-
class BizOffer < ActiveRecord::Base
  include AutoTypeName
  include BusinessFlow
  
  after_initialize :after_initialize
  
  validates_presence_of :business_id, :business_partner_id, :bp_pic_id, :biz_offer_status_type, :biz_offered_at
  
  has_many :approaches, :conditions => ["approaches.deleted = 0"]
  belongs_to :business
  belongs_to :business_partner
  belongs_to :bp_pic
  belongs_to :contact_pic, :class_name => 'User'
  belongs_to :sales_pic, :class_name => 'User'
  belongs_to :import_mail
  
  def after_initialize 
    init_actions([
      [:open, :approached, :approach],
      [:open, :other_failure, :choice_other],
      [:open, :lost_failure, :lost],
      [:open, :natural_lost, :pass_away],
      [:approached, :open, :reject_approach],
      [:approached, :working, :get_job],
      [:approached, :other_failure, :choice_other],
      [:approached, :lost_failure, :lost],
      [:approached, :natural_lost, :pass_away],
      [:working, :finished, :finish, ->(a){
        business.change_status(:finish)
        return a.to
      }],
      [:other_failure, :open, :revert],
      [:lost_failure, :open, :revert],
      [:natural_lost, :open, :revert],
    ])
  end

  def contact_employee_name
   if self.contact_pic_id
     employee = Employee.find(self.contact_pic_id)
     employee ? employee.employee_name : ""
   end
  end
  
  def sales_employee_name
   if self.sales_pic_id
     employee = Employee.find(self.sales_pic_id)
     employee ? employee.employee_name : ""
   end
  end
  
  def change_status_type
    
  end
  
  def payment_max_view=(x)
    self.payment_max = x.to_f * 10000
  end
  
  def payment_max_view
    payment_max.to_f / 10000.0
  end
end
