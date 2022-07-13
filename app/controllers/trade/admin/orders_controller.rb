module Trade
  class Admin::OrdersController < Admin::BaseController
    before_action :set_order, only: [
      :show, :payment_types, :edit, :update, :refund, :destroy,
      :payment_orders
    ]
    before_action :set_new_order, only: [:new, :create]

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:id, :uuid, :user_id, :member_id, :payment_status, :state, :payment_type)

      @orders = Order.includes(:user, :member, :member_organ).default_where(q_params).order(id: :desc).page(params[:page]).per(params[:per])
    end

    def payments
      q_params = {}
      q_params.merge! params.permit(:id, :payment_status, :uuid)

      @orders = Order.default_where(q_params).page(params[:page])
    end

    def new
      @order.trade_items.build
    end

    def create
      @order.agent_id = current_member.id

      if params[:commit].present? && @order.save
        render 'create'
      else
        render 'new'
      end
    end

    def payment_types
    end

    def refund
      @order.apply_for_refund
    end

    def payment_orders
      @payment_orders = @order.payment_orders
    end

    def payment_new
      @payment_order = PaymentOrder.new
      @payments = @order.pending_payments
    end

    def payment_create
      @payment_order = @order.payment_orders.build(payment_order_params)
      @order = @payment_order.order

      if @payment_order.save
        render 'create'
      else
        render 'create_fail'
      end
    end

    def payment_destroy
      if @payment_order.init?
        @payment_order.destroy
      end
    end

    private
    def set_order
      @order = Order.find(params[:id])
    end

    def set_new_order
      @order = Order.new order_params
    end

    def order_params
      p = params.fetch(:order, {}).permit(
        :state,
        :payment_id,
        :payment_type,
        :address_id,
        :from_address_id,
        :amount,
        :note,
        :payment_strategy_id,
        trade_items_attributes: [:organ_id, :good_type, :good_id, :good_name, :number, :weight, :volume, :note, :image],
        cart_promotes_attributes: [:promote_id]
      )
      p.merge! default_form_params
    end

  end
end
