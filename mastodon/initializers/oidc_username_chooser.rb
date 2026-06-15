module OidcUsernameChooser
  def openid_connect
    auth = request.env['omniauth.auth']
    identity = Identity.find_for_omniauth(auth)

    if identity.user.nil?
      # Extraire uniquement les rôles depuis le raw_info (pas le JWT entier)
      raw_roles = Array(auth.extra&.raw_info&.[]('roles'))

      session[:pending_oidc_auth] = {
        'provider'   => auth.provider,
        'uid'        => auth.uid,
        'email'      => auth.info.email,
        'name'       => auth.info.name || auth.info.full_name,
        'first_name' => auth.info.first_name,
        'last_name'  => auth.info.last_name,
        'id_token'   => auth.credentials&.id_token,
        'roles'      => raw_roles,
      }
      redirect_to '/auth/choose_username'
    else
      session[:oidc_id_token] = auth.credentials&.id_token
      super
    end
  end
end

Rails.application.config.to_prepare do
  Auth::OmniauthCallbacksController.prepend(OidcUsernameChooser)
end
