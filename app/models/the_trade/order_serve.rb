class OrderServe < ApplicationRecord
  belongs_to :order, inverse_of: :order_serves
  belongs_to :order_item, optional: true
  belongs_to :serve_charge, optional: true
  belongs_to :serve

end

# :order_id, :integer
# :order_item_id :integer

