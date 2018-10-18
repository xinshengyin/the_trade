# should define methods: buyer & buyer_id
module RailsTradeUser
  extend ActiveSupport::Concern

  included do
    attribute :provider_id, :integer
    belongs_to :provider, inverse_of: :users, autosave: true, optional: true
  end

end

