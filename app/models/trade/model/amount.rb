module Trade
  module Model::Amount
    extend ActiveSupport::Concern

    included do
      attribute :item_amount, :decimal, default: 0
      attribute :overall_additional_amount, :decimal, default: 0
      attribute :overall_reduced_amount, :decimal, default: 0
      attribute :original_amount, :decimal, default: 0, comment: '原价，应用优惠之前的价格'
      attribute :amount, :decimal, default: 0
      attribute :lock_version, :integer
      attribute :extra, :json, default: {}
    end

    def xx
      trade.amount += changed_amount
    end

    def compute_promote_hash
      promotes = available_promotes
      result = {}

      promotes.each do |promote, available_items|
        r = {}

        r[:value] = available_items.sum(&->(i){ i[:trade_item].metering_attributes[promote.metering] || 0 })
        r[:promote_charge] = promote.compute_charge(r[:value], **extra)
        if r[:promote_charge]
          r[:computed_amount] = r[:promote_charge].final_price(r[:value]) if r[:promote_charge]
        else
          r[:computed_amount] = nil
        end
        r[:items] = available_items

        result.merge! promote => r
      end

      result
    end

    def compute_promote
      result = compute_promote_hash
      if result.blank?
        cart_promotes.delete_all
      end
      sequences = result.keys.map!(&:sequence).sort!

      sequences.each do |sequence|
        x = result.select { |k, _| k.sequence == sequence }
        promote, answer = x.min_by { |_, v| v[:computed_amount] }
        cart_promotes.where(status: 'init').where.not(promote_id: promote.id).delete_all

        cp = cart_promotes.find(&->(i){ i.promote_id == promote.id }) || cart_promotes.build(promote_id: promote.id)
        answer[:items].each do |item|
          ip = cp.item_promotes.find_or_initialize_by(trade_item_id: item[:trade_item].id)
          ip.promote_good = item[:promote_good]
        end
        cp.based_amount = answer[:value]
        cp.promote_charge = answer[:promote_charge]
        cp.computed_amount = answer[:computed_amount]
        cp.sync_amount
      end
      self.sum_amount
      self.changes
    end

    def reset_amount
      self.sum_amount
      self.valid?
      self.changes
    end

    def reset_amount!(*args)
      self.reset_amount
      self.save(*args)
    end

  end
end
