module Trade
  class Admin::PromoteGoodCardsController < Admin::BaseController
    before_action :set_card_template
    before_action :set_promote_good_card, only: [:show, :edit, :update, :destroy, :actions]
    before_action :set_new_promote_good_card, only: [:new, :create]
    before_action :set_promotes, only: [:new, :edit]

    def index
      @promote_good_cards = @card_template.promote_good_cards.page(params[:page])
    end

    private
    def set_card_template
      @card_template = CardTemplate.find params[:card_template_id]
    end

    def set_promote_good_card
      @promote_good_card = CardPromote.find(params[:id])
    end

    def set_new_promote_good_card
      @promote_good_card = @card_template.promote_good_cards.build(promote_good_card_params)
    end

    def set_promotes
      @promotes = Promote.default_where(default_params)
    end

    def promote_good_card_params
      params.fetch(:promote_good_card, {}).permit(
        :good_type,
        :promote_id
      )
    end

  end
end
