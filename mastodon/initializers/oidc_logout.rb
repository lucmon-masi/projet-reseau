module OidcSingleLogout
  # Capture id_token BEFORE Devise calls reset_session in destroy.
  # after_sign_out_path_for is called after the session is wiped,
  # so we save it to an instance variable first.
  def destroy
    @oidc_id_token_for_logout = session[:oidc_id_token]
    super
  end

  def after_sign_out_path_for(_resource_or_scope)
    return super unless ENV['OIDC_ENABLED'] == 'true'

    issuer       = ENV.fetch('OIDC_ISSUER', '').chomp('/')
    redirect_uri = "https://#{ENV.fetch('LOCAL_DOMAIN')}/"

    params = { post_logout_redirect_uri: redirect_uri }
    if @oidc_id_token_for_logout.present?
      params[:id_token_hint] = @oidc_id_token_for_logout
    else
      # Keycloak requires id_token_hint OR client_id when post_logout_redirect_uri is set
      params[:client_id] = ENV.fetch('OIDC_CLIENT_ID', 'mastodon')
    end

    "#{issuer}/protocol/openid-connect/logout?#{params.to_query}"
  end
end

Rails.application.config.to_prepare do
  Auth::SessionsController.prepend(OidcSingleLogout)
end
