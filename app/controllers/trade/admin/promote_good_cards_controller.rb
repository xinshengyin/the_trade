module Trade
  class Admin::PromoteGoodCardsController < Admin::BaseController
    before_action :set_card_template
    before_action :set_promote_good_card, only: [:show, :edit, :update, :destroy, :actions]
    before_action :set_new_promote_good_card, only: [:new, :create]

    def index
      @promote_good_cards = @card_template.promote_good_cards
      promote_ids = @promote_good_cards.pluck(:promote_id)
      @promotes = Promote.default_where(default_params)
    end

    private
    def set_card_template
      @card_template = CardTemplate.find params[:card_template_id]
    end

    def set_promote_good_card
      @promote_good_card = PromoteGoodCard.default_where(default_params).find(params[:id])
    end

    def set_new_promote_good_card
      @promote_good_card = @card_template.promote_good_cards.build(promote_good_card_params)
    end

    def promote_good_card_params
      _p = params.fetch(:promote_good_card, {}).permit(
        :promote_id,
        :good_type,
        :good_id,
        :effect_at,
        :expire_at,
        :use_limit,
        :status
      )
      _p.with_defaults! promote_id: params[:promote_id], good_type: 'Factory::Production'
      _p
    end

  end
end