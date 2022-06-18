module Trade
  class TradeItem < ApplicationRecord
    include Model::TradeItem
    include Ordering::Rent
    include Job::Ext::Jobbed
  end
end
