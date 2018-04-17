class RegistrationsPaymentController < RegistrationsController

  def create
    if !params[:stripe_token].present?
      logger.info "event=registration status=failure errors='Stripe token not present. Can't create account.'"
      render action: "new"
    else
      super
      if @user.errors.size == 0
        stripe = Stripe::Customer.create(
          :email => "#{@user.username}@diasp.eu",
          :card => params[:stripe_token],
          :plan => "diaspora"
        )
        @user.stripe_last4 = stripe.cards.data.first["last4"]
        @user.stripe_id = stripe.id
        @user.save
      end
    end
  end
end
