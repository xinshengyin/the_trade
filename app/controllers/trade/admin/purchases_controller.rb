module Trade
  class Admin::PurchasesController < Admin::BaseController
    before_action :set_card_template
    before_action :set_purchase, only: [:show, :edit, :update, :destroy]
    before_action :set_new_purchase, only: [:new, :create]

    def index
      @purchases = @card_template.purchases.order(id: :desc).page(params[:page])
    end

    private
    def set_card_template
      @card_template = CardTemplate.find params[:card_template_id]
    end

    def set_purchase
      @purchase = @card_template.purchases.find(params[:id])
    end

    def set_new_purchase
      @purchase = @card_template.purchases.build(purchase_params)
    end

    def purchase_params
      params.fetch(:purchase, {}).permit(
        :price,
        :title,
        :days,
        :months,
        :years,
        :note,
        :default
      )
    end
  end
end
