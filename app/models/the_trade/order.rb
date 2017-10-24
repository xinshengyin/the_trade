class Order < ApplicationRecord

  belongs_to :payment_strategy, optional: true
  belongs_to :buyer
  has_many :payment_orders, inverse_of: :order, dependent: :destroy
  has_many :payments, through: :payment_orders
  has_many :order_items, dependent: :destroy, autosave: true
  has_many :refunds, dependent: :nullify

  accepts_nested_attributes_for :order_items

  scope :credited, -> { where(payment_strategy_id: self.credit_ids) }


  after_initialize if: :new_record? do |o|
    self.uuid = UidHelper.nsec_uuid('OD')
  end

  enum payment_status: {
    unpaid: 0,
    part_paid: 1,
    all_paid: 2,
    refunding: 3,
    refunded: 4
  }
  enum payment_type: {
    paypal: 'paypal',
    alipay: 'alipay',
    stripe: 'stripe'
  }

  def unreceived_amount
    self.amount - self.received_amount
  end

  def init_received_amount
    self.payment_orders.sum(:check_amount)
  end

  def pending_payments
    Payment.where.not(id: self.payment_orders.pluck(:payment_id)).where(payment_method_id: self.buyer.payment_method_ids, state: ['init', 'part_checked'])
  end

  def exists_payments
    Payment.where.not(id: self.payment_orders.pluck(:payment_id)).exists?(payment_method_id: self.buyer.payment_method_ids, state: ['init', 'part_checked'])
  end

  def pay_result
    if self.amount == 0
      return paid_result
    end

    if self.payment_status == 'all_paid'
      return self
    end

    if self.paypal?
      self.paypal_result
    elsif self.alipay?
      self.alipay_result
    elsif self.stripe?
      self.stripe_result
    end
    self
  end

  def paid_result
    self.payment_status = 'all_paid'
    self.received_amount = self.amount
    self.confirm_paid!
    self
  end

  def apply_for_refund(payment_id = nil)
    if self.payments.size == 1
      payment = self.payments.first
    else
      payment = self.payments.find_by(id: payment_id)
    end

    refund = Refund.find_or_initialize_by(order_id: self.id, payment_id: payment.id)
    refund.type = payment.type.sub(/Payment/, '') + 'Refund'
    refund.total_amount = payment.total_amount
    refund.currency = payment.currency

    self.payment_status = 'refunding'
    self.received_amount -= payment.total_amount

    self.class.transaction do
      self.save!
      self.confirm_refund!
      refund.save!
    end
  end

  def confirm_paid!

  end
  
  def confirm_refund!

  end

  def check_state
    if self.received_amount.to_d >= self.amount
      self.payment_status = 'all_paid'
      self.confirm_paid!
    elsif self.received_amount.to_d > 0 && self.received_amount.to_d < self.amount
      self.payment_status = 'part_paid'
    elsif self.received_amount.to_d <= 0
      self.payment_status = 'unpaid'
    end
  end

  def check_state!
    self.check_state
    self.save!
  end

  def self.credit_ids
    PaymentStrategy.where.not(period: 0).pluck(:id)
  end

end

# payment_id
# payment_type
# amount
# received_amount
