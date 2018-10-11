class Trade::BuyersController < ApplicationController

  def search
    @buyers = RailsTrade.buyer_class.default_where('name-like': params[:q])
    render json: { results: @buyers.as_json(only: [:id], methods: [:name_detail]) }
  end

end
