module Trade
  module Model::Order
    extend ActiveSupport::Concern

    included do
      attribute :uuid, :string
      attribute :myself, :boolean, default: true
      attribute :note, :string
      attribute :expire_at, :datetime, default: -> { Time.current + RailsTrade.config.expire_after }
      attribute :serial_number, :string
      attribute :extra, :json, default: {}
      attribute :currency, :string, default: RailsTrade.config.default_currency
      attribute :trade_items_count, :integer, default: 0
      attribute :paid_at, :datetime, index: true
      attribute :pay_later, :boolean, default: false

      belongs_to :organ, class_name: 'Org::Organ', optional: true

      belongs_to :user, class_name: 'Auth::User', optional: true
      belongs_to :member, class_name: 'Org::Member', optional: true
      belongs_to :member_organ, class_name: 'Org::Organ', optional: true
      belongs_to :agent, class_name: 'Org::Member', optional: true
      belongs_to :address, class_name: 'Profiled::Address', optional: true
      belongs_to :produce_plan, class_name: 'Factory::ProducePlan', optional: true  # 统一批次号

      belongs_to :payment_strategy, optional: true

      has_many :carts, ->(o){ where(organ_id: o.organ_id, member_id: [o.member_id, nil]) }, foreign_key: :user_id, primary_key: :user_id
      has_many :refunds, inverse_of: :order, dependent: :nullify
      has_many :payment_orders, dependent: :destroy_async
      has_many :payments, through: :payment_orders, inverse_of: :orders
      has_many :promote_goods, -> { available }, foreign_key: :user_id, primary_key: :user_id
      has_many :promotes, through: :promote_goods
      has_many :trade_items, inverse_of: :order
      has_many :cart_promotes, autosave: true, dependent: :nullify  # overall can be blank
      accepts_nested_attributes_for :trade_items
      accepts_nested_attributes_for :cart_promotes

      scope :credited, -> { where(payment_strategy_id: PaymentStrategy.where.not(period: 0).pluck(:id)) }
      scope :to_pay, -> { where(payment_status: ['unpaid', 'part_paid']) }

      enum state: {
        init: 'init',
        done: 'done',
        canceled: 'canceled'
      }, _default: 'init'

      enum payment_status: {
        unpaid: 'unpaid',
        to_check: 'to_check',
        part_paid: 'part_paid',
        all_paid: 'all_paid',
        refunding: 'refunding',
        refunded: 'refunded',
        denied: 'denied'
      }, _default: 'unpaid'

      before_validation :sum_amount, if: :new_record?
      before_validation :init_from_member, if: -> { member && member_id_changed? }
      before_validation :init_uuid, if: -> { uuid.blank? }
      before_create :init_pay_later
      before_save :init_serial_number, if: -> { paid_at.present? && paid_at_changed? }
      after_create_commit :confirm_ordered!
    end

    def init_uuid
      self.uuid = UidHelper.nsec_uuid('OD')
      self
    end

    def init_from_member
      self.user = member.user
      self.member_organ_id = member.organ_id
      self
    end

    def init_serial_number
      last_item = self.class.where(organ_id: self.organ_id).default_where('paid_at-gte': paid_at.beginning_of_day, 'paid_at-lte': paid_at.end_of_day).order(paid_at: :desc).first

      if last_item
        self.serial_number = last_item.serial_number.to_i + 1
      else
        self.serial_number = (paid_at.strftime('%Y%j') + '0001').to_i
      end
    end

    def init_pay_later
      self.pay_later = true if should_pay_later?
    end

    def should_pay_later?
      trade_items.pluck(:aim).include?('rent')
    end

    def subject
      r = trade_items.map { |oi| oi.good.name.presence }.join(', ')
      r.presence || 'goods'
    end

    def user_name
      user&.name.presence || "#{user_id}"
    end

    def can_cancel?
      init? && ['unpaid', 'to_check'].include?(self.payment_status)
    end

    def amount_money
      amount_to_money(self.currency)
    end

    def available_promotes
      promotes = {}

      trade_items.each do |item|
        item.available_promotes.each do |promote_id, detail|
          promotes[promote_id] ||= []
          promotes[promote_id] << detail
        end
      end

      promotes.transform_keys!(&->(i){ Promote.find(i) })
    end

    def sum_amount
      self.item_amount = trade_items.sum(&:amount)
      self.overall_additional_amount = cart_promotes.select(&->(o){ o.amount >= 0 }).sum(&:amount)
      self.overall_reduced_amount = cart_promotes.select(&->(o){ o.amount < 0 }).sum(&:amount)
      self.amount = item_amount + overall_additional_amount + overall_reduced_amount
    end

    def confirm_ordered!
      self.carts.each do |cart|
        cart.reset_amount!
      end
      self.trade_items.update(status: 'ordered')
    end

    def compute_received_amount
      _received_amount = self.payment_orders.select(&->(o){ o.confirmed? }).sum(&:check_amount)
      _refund_amount = self.refunds.where.not(state: 'failed').sum(:total_amount)
      _received_amount - _refund_amount
    end

  end
end
