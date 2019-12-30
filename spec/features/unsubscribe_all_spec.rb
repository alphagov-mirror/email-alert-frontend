RSpec.feature "Bulk unsubscribe after receiving confirmation link" do
  include GdsApi::TestHelpers::EmailAlertApi
  include TokenHelper

  scenario do
    given_i_have_multiple_subscriptions
    when_i_visit_the_manage_my_subscriptions_page
    and_i_click_on_unsubscribe_from_everything
    and_i_confirm_to_unsubscribe
    then_i_can_see_i_have_been_unsubscribed
  end

  def given_i_have_multiple_subscriptions
    @address = "test@test.com"
    @subscriber_id = 123
    stub_email_alert_api_has_subscriber_subscriptions(
      @subscriber_id,
      @address,
      nil,
      subscriptions: [subscription, subscription],
    ).times(3)
     .then
     .to_return(status: 200, body: subscriber_with_no_subscriptions_response)
  end

  def when_i_visit_the_manage_my_subscriptions_page
    token = jwt_token(data: {
      "address" => @address,
      "subscriber_id" => @subscriber_id,
    })
    visit process_sign_in_token_path(token: token)
  end

  def and_i_click_on_unsubscribe_from_everything
    click_on "Unsubscribe from everything"
  end

  def and_i_confirm_to_unsubscribe
    @request = stub_email_alert_api_unsubscribes_a_subscriber(@subscriber_id)
    click_on "Unsubscribe"
  end

  def then_i_can_see_i_have_been_unsubscribed
    expect(@request).to have_been_requested
    expect(page).to have_content("You have been unsubscribed from all your subscriptions")
  end

private

  def subscription
    {
      "id" => SecureRandom.uuid,
      "created_at" => Time.zone.now,
      "subscriber_list" => {
        "id" => SecureRandom.uuid,
      },
    }
  end

  def subscriber_with_no_subscriptions_response
    {
      "subscriber" => {
        "id" => @subscriber_id,
        "address" => @address,
      },
      "subscriptions" => [],
    }.to_json
  end
end
