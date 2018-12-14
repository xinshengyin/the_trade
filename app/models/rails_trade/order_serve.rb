class OrderServe < ApplicationRecord
  attribute :order_id, :integer
  attribute :order_item_id, :integer

  belongs_to :order, inverse_of: :order_serves
  belongs_to :order_item, optional: true
  belongs_to :serve_charge, optional: true
  belongs_to :serve

end unless RailsTrade.config.disabled_models.include?('OrderServe')
