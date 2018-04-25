class ApplicationController < ActionController::Base
  include Slimmer::Template
  include Slimmer::GovukComponents

  before_action :set_cache_control_header

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  rescue_from GdsApi::HTTPNotFound, with: :error_not_found
  rescue_from GdsApi::HTTPGone, with: :gone

private

  def set_cache_control_header
    response.cache_control[:private] = true
    response.cache_control[:extras] = ['no-cache']
  end

  def error_not_found
    render status: :not_found, plain: "404 not found"
  end

  def gone
    render status: :gone, plain: "410 gone"
  end

  def require_authentication
    redirect_to :sign_in unless authenticated?
  end

  def authenticated?
    session["authentication"].present?
  end

  def authenticated_subscriber_id
    # session isn't a real hash and doesn't respond to dig
    session["authentication"]&.fetch("subscriber_id", nil)
  end
end
