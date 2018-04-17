class UsersPaymentController < UsersController

  def destroy
    stripe_error = false
    if current_user && !current_user.stripe_id.blank?
      begin
        customer = Stripe::Customer.retrieve(current_user.stripe_id)
        subscription = customer.subscriptions.data[0]
        if subscription && (subscription.status == 'active' or subscription.status == 'trialing')
          customer.cancel_subscription
        end
      rescue Stripe::StripeError => e
        logger.error "Unable to cancel Stripe subscription: Error: " + e.message
        stripe_error = true
        redirect_back fallback_location: edit_user_path
      end
    end
    super unless stripe_error # UsersController#destroy
  end
  
  def donate_settings
    @user = current_user
  end
  
  def update_donate_settings
    if !params[:stripe_token].present?
      logger.info "event=update_donate_settings status=failure errors='Stripe token not present. Can't create account.'"
      render action: "donate_settings"
    else
      if current_user.stripe_id.blank?
        # create user
        stripe = Stripe::Customer.create(
          :email => "#{current_user.username}@diasp.eu",
          :card => params[:stripe_token],
          :plan => "diaspora"
        )
      else
        # update user
        stripe = Stripe::Customer.retrieve(current_user.stripe_id)
        stripe.card = params[:stripe_token]
        stripe.save
      end
      
      current_user.stripe_last4 = stripe.cards.data.first["last4"]
      current_user.stripe_id = stripe.id
      
      if current_user.save
        flash[:notice] = t("users.update.settings_updated")
      else
        flash[:error] = t("users.update.settings_not_updated")
      end
    end

    redirect_back fallback_location: donate_settings_path
  end
end
