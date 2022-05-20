module Trade
  module Controller::Application
    extend ActiveSupport::Concern

    included do
      helper_method :current_cart, :current_cart_count, :current_wallet
    end

    def current_cart
      return @current_cart if @current_cart

      if current_user
        options = {}
        options.merge! default_form_params
        if params[:global_member_id]
          options.merge! member_id: params[:global_member_id].delete_prefix('member_')
        else
          options.merge! member_id: nil
        end
        @current_cart = current_user.carts.find_by(options) || current_user.carts.create(options)
      end
      logger.debug "\e[33m  Current Trade cart: #{@current_cart&.id}  \e[0m"
      @current_cart
    end

    def current_wallet
      return @current_wallet if @current_wallet

      wallet_template = WalletTemplate.default_where(default_params).default.take
      if wallet_template
        @current_wallet = current_user.wallets.find_or_initialize_by(wallet_template_id: wallet_template.id)
      end

      @current_wallet
    end

    def current_cart_count
      if current_cart
        #current_cart.trade_items.size # 不去数据库计算数量
        current_cart.trade_items.count
      else
        0
      end
    end

  end
end
