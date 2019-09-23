require "rails_helper"
require "gds_api/test_helpers/email_alert_api"

RSpec.describe "subscribing", type: :feature do
  include GdsApi::TestHelpers::EmailAlertApi

  let(:topic_id) { "GOVUK_123" }
  let(:subscriber_list_id) { 10 }
  let(:address) { "test@test.com" }
  let(:frequency) { "weekly" }

  before do
    stub_email_alert_api_has_subscriber_list_by_slug(
      slug: topic_id,
      returned_attributes: {
        id: subscriber_list_id,
        title: "Test Subscriber List",
      },
    )

    returned_subscription_id = 50
    email_alert_api_creates_a_subscription(
      subscriber_list_id,
      address,
      frequency,
      returned_subscription_id,
    )
  end

  feature "signing up a for a subscription" do
    it "subscribes and renders the success page" do
      visit "/email/subscriptions/new?topic_id=#{topic_id}"

      expect(page).to have_content("How often do you want to get updates?")
      choose "frequency", option: frequency, visible: false

      click_on "Next"

      expect(page).to have_content("What’s your email address?")
      fill_in :address, with: address

      click_on "Subscribe"

      expect(page).to have_content("You’ve subscribed successfully")
      expect(page).to have_content("Test Subscriber List")
    end
  end

  feature "signing up for a subscription without default frequency parameter" do
    it "should default to immediately" do
      visit "/email/subscriptions/new?topic_id=#{topic_id}"
      expect(find_field(name: "frequency", checked: true).value).to eq "immediately"
    end
  end

  feature "signing up for a subscription with a default frequency specified" do
    it "should change the pre-selected option based on `default_frequency` parameter" do
      visit "/email/subscriptions/new?topic_id=#{topic_id}&default_frequency=daily"
      expect(find_field(name: "frequency", checked: true).value).to eq "daily"
    end
  end

  feature "back link navigation" do
    let(:new_subscription_path) { "/email/subscriptions/new?topic_id=#{topic_id}" }
    let(:new_subscription_path_regex) do
      Regexp.new(
        Regexp.escape(new_subscription_path),
      )
    end

    context "arrived at form with referer" do
      it "has a link to the referer forced onto the gov.uk domain" do
        page.driver.header("Referer", "http://example.com/some/page?query=string")
        visit new_subscription_path
        expect(back_link_href).to match(%r{gov.uk/some/page\?query=string$})
      end
    end

    context "arrived at form without referer" do
      it "links to govuk website root" do
        visit new_subscription_path
        expect(back_link_href).to match(%r{gov.uk$})
      end
    end

    context "on address page" do
      it "links to the first part of the form" do
        visit "/email/subscriptions/new?topic_id=#{topic_id}&frequency=#{frequency}"
        expect(back_link_href).to match(new_subscription_path_regex)
      end
    end

    context "on complete page" do
      it "links to the first part of the form" do
        visit "/email/subscriptions/complete?topic_id=#{topic_id}&frequency=#{frequency}"
        expect(back_link_href).to match(new_subscription_path_regex)
      end
    end
  end

  def back_link_href
    page.find("a", text: "Back")[:href]
  end
end
