module Trade
  class Our::ItemsController < My::ItemsController
    before_action :set_item, only: [:show, :promote, :update, :toggle, :destroy]
    before_action :set_new_item, only: [:create]

    def create
      @item.agent_id = params[:agent_id]
      @item.save
    end

    def promote
      render layout: false
    end

    private
    def set_new_item
      options = {
        user_id: current_user.id,
        member_id: current_member.id
      }
      options.merge! params.permit(:good_type, :good_id, :aim, :number, :produce_on, :scene_id, :fetch_oneself)

      @item = Item.new(**options.to_h.symbolize_keys)
    end

    def set_item
      @item = current_member.items.find(params[:id])
    end

    def item_params
      params.fetch(:item, {}).permit(
        :number
      )
    end

  end
end