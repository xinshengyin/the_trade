module Trade
  module Model::RefundOrder
    extend ActiveSupport::Concern

    included do
      attribute :payment_amount, :decimal
      attribute :order_amount, :decimal, comment: '对应的订单金额'

      enum state: {
        init: 'init',
        refunding: 'refunding',
        refunded: 'refunded'
      }, _default: 'init', _prefix: true

      belongs_to :order, inverse_of: :refund_orders
      belongs_to :payment
      belongs_to :refund

      has_many :refunds, foreign_key: :payment_id, primary_key: :payment_id

      after_update :sync_to_payment_and_order!, if: -> { state_refunding? && (saved_changes.keys & ['state', 'payment_amount', 'order_amount']).present? }
      after_update :revert_to_payment_and_order!, if: -> { state_init? && state_before_last_save == 'refunding' }
      #after_destroy_commit :unchecked_to_order!
    end

    def sync_to_payment_and_order!
      payment.refuned_amount += self.payment_amount

      order.refund_amount += self.order_amount
      order.unreceived_amount = order.amount - order.received_amount - order.refund_amount

      self.class.transaction do
        payment.save!
        order.save!
      end
    end

    def revert_to_payment_and_order!
      payment.refuned_amount -= self.payment_amount

      order.refund_amount -= self.order_amount
      order.unreceived_amount = order.amount - order.received_amount - order.refund_amount

      self.class.transaction do
        payment.save!
        order.save!
      end
    end

  end
end
