module Trade
  class Admin::ScanPaymentsController < Admin::BaseController
    before_action :set_new_scan_payment, only: [:new, :create]

    def index
      q_params = {}
      q_params.merge! default_params

      @scan_payments = ScanPayment.default_where(q_params).order(id: :desc).page(params[:page])
    end

    def create
      auth_code = params[:result].split(',')[-1]

      @scan_payment.app_payee = current_payee
      @scan_payment.micro_pay!(auth_code: auth_code, spbill_create_ip: request.remote_ip)
    end

    private
    def set_new_scan_payment
      @scan_payment = ScanPayment.new(scan_payment_params)
    end

    def scan_payment_params
      p = params.fetch(:scan_payment, {}).permit(
        :total_amount
      )
      p.merge! default_form_params
    end

  end
end