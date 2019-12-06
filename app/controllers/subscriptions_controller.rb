class SubscriptionsController < ApplicationController
  include FrequenciesHelper
  before_action :assign_attributes
  before_action :assign_back_url

  def new
    if @frequency.present?
      return frequency_form_redirect unless valid_frequency

      render :new_address
    else
      render :new_frequency
    end
  end

  def frequency
    if @frequency.present?
      return frequency_form_redirect unless valid_frequency

      redirect_to new_subscription_path(
        topic_id: @topic_id,
        frequency: @frequency,
      )
    else
      flash.now[:error] = t("subscriptions.new_frequency.missing_frequency")
      render :new_frequency
    end
  end

  def create
    return frequency_form_redirect unless valid_frequency

    if @address.present? && subscribe
      render :check_email
    else
      flash.now[:error] = if @address.present?
                            t("subscriptions.new_address.invalid_email")
                          else
                            t("subscriptions.new_address.missing_email")
                          end
      render :new_address
    end
  end

  def complete; end

private

  def assign_attributes
    @topic_id = subscription_params.require(:topic_id)
    @subscriber_list = email_alert_api
      .get_subscriber_list(slug: @topic_id)
      .to_h.fetch("subscriber_list")
    @frequency = subscription_params[:frequency]
    @address = subscription_params[:address]
    @title = @subscriber_list["title"]
  end

  def assign_back_url
    @back_url = url_for(action: :new, topic_id: @topic_id)
    @back_url = govuk_url if params[:action] == "new" && !@frequency.present?
  end

  def subscription_params
    params.permit(:topic_id, :address, :frequency, :default_frequency)
  end

  def valid_frequency
    valid_frequencies.include?(@frequency)
  end

  def frequency_form_redirect
    redirect_to new_subscription_path(topic_id: @topic_id)
  end

  def govuk_url
    referer = request.referer

    if referer && referer.exclude?("/email/subscriptions")
      referer_uri = URI(referer)
      sanitised_referer_uri = Plek.new.website_uri
      sanitised_referer_uri.path = referer_uri.path
      sanitised_referer_uri.query = referer_uri.query
      sanitised_referer_uri.fragment = referer_uri.fragment
      sanitised_referer_uri.to_s
    elsif @subscriber_list["url"]&.match?(%r{^/get-ready-brexit-check/results})
      (Plek.new.website_root + @subscriber_list["url"]).to_s
    else
      Plek.new.website_root
    end
  end

  def subscribe
    email_alert_api.send_subscription_verification_email(
      topic_id: @topic_id,
      address: @address,
      frequency: @frequency,
    )
  rescue GdsApi::HTTPUnprocessableEntity
    false
  end

  def email_alert_api
    EmailAlertFrontend.services(:email_alert_api)
  end
end
