RSpec.feature "Content item signup" do
  include GovukContentSchemaExamples
  include GdsApi::TestHelpers::EmailAlertApi

  scenario do
    given_there_is_a_topic
    when_i_visit_the_topic_signup_page
    and_i_refine_my_selection
    and_i_click_to_signup_to_alerts
    then_i_can_subscribe_to_alerts
  end

  def given_there_is_a_topic
    @taxon = {
      content_id: "taxon-uuid",
      base_path: "/education/further-education",
      title: "Further education",
      document_type: "taxon",
      phrase: "live",
      links: {
        parent_taxons: [
          {
            base_path: "/education",
            title: "Education",
            description: "Education content",
            links: {},
          },
        ],
        child_taxons: [
          {
            base_path: "/education/funding",
            title: "Funding",
            links: {
              parent_taxons: [
                {
                  base_path: "/education/further-education",
                  title: "Further education",
                  links: {},
                },
              ],
            },
          },
        ],
      },
    }

    content_store_has_item(@taxon[:base_path], @taxon)

    content_store_has_item(
      @taxon.dig(:links, :parent_taxons).first[:base_path],
      @taxon.dig(:links, :parent_taxons).first,
    )
  end

  def when_i_visit_the_topic_signup_page
    stub_email_alert_api_has_subscriber_list_by_slug(
      slug: @taxon[:base_path],
      returned_attributes: {
        "title" => @taxon[:title],
      },
    )

    visit new_content_item_signup_path(topic: @taxon[:base_path])
    expect(page).to have_content(@taxon[:title])
    expect(page).to have_content(@taxon.dig(:links, :child_taxons).first[:title])
  end

  def and_i_refine_my_selection
    choose @taxon[:title]
    click_button "Select"
  end

  def and_i_click_to_signup_to_alerts
    subscriber_list_id = @taxon[:base_path]
    @subscriber_list_url = new_subscription_path(topic_id: subscriber_list_id)

    stub_email_alert_api_has_subscriber_list(
      "links" => { "taxon_tree" => [@taxon[:content_id]] },
      "id" => @taxon[:base_path],
      "subscription_url" => @subscriber_list_url,
    )

    # Based on the position of this taxon in the taxonomy:
    expect(page).to have_content("This might be between 0 - 20 updates a week")
    expect(page).to have_content("You can set your preferences once you've signed up.")

    click_on "Sign up now"
  end

  def then_i_can_subscribe_to_alerts
    expect(page).to have_current_path(@subscriber_list_url)
  end
end
