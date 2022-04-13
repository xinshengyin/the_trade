module Trade
  module Model::ItemPromote
    extend ActiveSupport::Concern

    included do
      attribute :sequence, :integer
      attribute :amount, :decimal, default: 0, comment: ''
      attribute :promote_name, :string

      belongs_to :organ, class_name: 'Org::Organ', optional: true
      belongs_to :user, class_name: 'Auth::User', optional: true
      belongs_to :member, class_name: 'Org::Member', optional: true
      belongs_to :member_organ, class_name: 'Org::Organ', optional: true

      belongs_to :cart_promote, inverse_of: :item_promotes, optional: true
      belongs_to :trade_item, inverse_of: :item_promotes
      belongs_to :promote
      belongs_to :promote_charge
      belongs_to :promote_good

      enum status: {
        init: 'init',
        checked: 'checked',
        ordered: 'ordered'
      }, _default: 'init'

      validates :amount, presence: true

      after_initialize if: :new_record? do
        if trade_item
          self.order = trade_item.order
        end
        if self.promote_good
          self.promote_id = self.promote_good.promote_id
        end
        self.sequence = self.promote.sequence if self.promote
      end
      after_create_commit :check_promote_good, if: -> { promote_good.present? }
    end

    def compute_amount
      self.based_amount = value + added_amount
      self.computed_amount = self.promote_charge.final_price(based_amount)
      self.amount = computed_amount unless edited?
      self
    end

    def check_promote_good
      promote_good.update state: 'used'
    end

  end
end
