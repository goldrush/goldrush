# -*- encoding: utf-8 -*-
require 'application_util'
class PaymentPerCase < ActiveRecord::Base
  include AutoTypeName
  include ApplicationUtil

  has_many :expense_details, :conditions => "deleted = 0", :order => "buy_date"
  belongs_to :payment_per_month
  belongs_to :base_application
  belongs_to :user

  def cutoff?
    cutoff_status_type == 'closed'
  end

end
