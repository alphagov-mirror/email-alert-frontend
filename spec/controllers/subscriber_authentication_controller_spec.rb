RSpec.describe SubscriberAuthenticationController do
  include GdsApi::TestHelpers::EmailAlertApi
  include TokenHelper

  let(:endpoint) { GdsApi::TestHelpers::EmailAlertApi::EMAIL_ALERT_API_ENDPOINT }
  let(:subscriber_id) { 1 }
  let(:subscriber_address) { "test@example.com" }

  render_views

  before do
    stub_email_alert_api_creates_an_auth_token(subscriber_id, subscriber_address)
  end

  describe "GET /email/authenticate" do
    context "when the page is requested" do
      it "returns 200" do
        get :sign_in
        expect(response).to have_http_status(:ok)
      end

      it "sets the Cache-Control header to 'private, no-cache'" do
        get :sign_in
        expect(response.headers["Cache-Control"]).to eq("private, no-cache")
      end

      it "renders a form" do
        get :sign_in
        expect(response.body).to include(%(action="#{request_sign_in_token_path}"))
      end
    end
  end

  describe "POST /email/authenticate" do
    context "when no address is provided" do
      let(:subscriber_address) { "" }

      it "renders an error message" do
        post :request_sign_in_token, params: { address: subscriber_address }
        expect(response.body).to include(SubscriberAuthenticationController::MISSING_EMAIL_ERROR)
      end
    end

    context "when an invalid address is provided" do
      let(:subscriber_address) { "foobar" }

      before do
        stub_email_alert_api_invalid_auth_token
      end

      it "renders an error message" do
        post :request_sign_in_token, params: { address: subscriber_address }
        expect(response.body).to include(SubscriberAuthenticationController::INVALID_EMAIL_ERROR)
      end
    end

    context "when a valid address is provided and the subscriber doesn't exist" do
      before do
        stub_email_alert_api_auth_token_no_subscriber
      end

      it "renders a message" do
        post :request_sign_in_token, params: { address: subscriber_address }
        expect(response.body).to include("We’ve sent an email to #{subscriber_address}")
      end
    end

    context "when a valid address is provided and the subscriber exists" do
      it "renders a message" do
        post :request_sign_in_token, params: { address: subscriber_address }
        expect(response.body).to include("We’ve sent an email to #{subscriber_address}")
      end
    end
  end

  describe "GET /email/authenticate/process" do
    let(:token) do
      jwt_token(data: {
        "subscriber_id" => subscriber_id,
        "redirect" => "/email/manage",
      })
    end

    context "when the page is requested" do
      it "sets the Cache-Control header to 'private, no-cache'" do
        get :process_sign_in_token, params: { token: token }
        expect(response.headers["Cache-Control"]).to eq("private, no-cache")
      end
    end

    context "when an expired token is provided" do
      let(:expired_token) { jwt_token(expiry: 5.minutes.ago) }

      it "redirects to sign in" do
        get :process_sign_in_token, params: { token: expired_token }
        expect(response).to redirect_to(sign_in_path)
      end

      it "sets a bad_token flash" do
        get :process_sign_in_token, params: { token: expired_token }
        expect(flash[:error_summary]).to eq("bad_token")
      end
    end

    context "when a valid token is provided" do
      it "redirects to the subscription management page" do
        get :process_sign_in_token, params: { token: token }
        expect(response).to redirect_to(list_subscriptions_path)
      end
    end
  end
end
