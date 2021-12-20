module Trade
  class My::CardTemplatesController < My::BaseController
    before_action :set_card_template, only: [:show]
    before_action :set_card_templates

    def index
      q_params = {}
      q_params.merge! default_params

      @card_templates = CardTemplate.default_where(q_params).page(params[:page])
    end

    def show
      @card = current_cart.cards.find_by(card_template_id: @card_template.id)
    end

    private
    def set_card_template
      @card_template = CardTemplate.default_where(default_params).find(params[:id])
    end

    def set_card_templates
      @card_templates = CardTemplate.default_where(default_params)
    end

  end
end
