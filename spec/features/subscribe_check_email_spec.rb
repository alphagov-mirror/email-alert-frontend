RSpec.feature "Subscribe" do
  include GdsApi::TestHelpers::EmailAlertApi

  scenario do
    given_there_is_content_i_can_subscribe_to
    when_i_visit_the_email_signup_page
    and_i_choose_a_frequency
    and_i_enter_my_email_address
    then_i_expect_to_get_an_email
  end

  def given_there_is_content_i_can_subscribe_to
    @topic_id = SecureRandom.uuid
    @subscriber_list_id = SecureRandom.uuid

    stub_email_alert_api_has_subscriber_list_by_slug(
      slug: @topic_id,
      returned_attributes: {
        id: @subscriber_list_id,
        title: "Test Subscriber List",
      },
    )
  end

  def when_i_visit_the_email_signup_page
    visit new_subscription_path(topic_id: @topic_id)
  end

  def and_i_choose_a_frequency
    expect(page).to have_content(I18n.t!("subscriptions.new_frequency.title"))
    @frequency = "weekly"
    choose "frequency", option: @frequency, visible: false
    click_on "Continue"
  end

  def and_i_enter_my_email_address
    expect(page).to have_content(I18n.t!("subscriptions.new_address.title"))

    address = "test@test.com"
    fill_in :address, with: address

    @request = stub_email_alert_api_sends_subscription_verification_email(
      address,
      @frequency,
      @topic_id,
    )

    click_on "Continue"
  end

  def then_i_expect_to_get_an_email
    expect(@request).to have_been_requested
    expect(page).to have_content(I18n.t!("subscriptions.check_email.title"))
  end
end
