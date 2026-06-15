module OidcRoleSync
  def openid_connect
    # Store id_token before super so it's available for SLO
    auth = request.env['omniauth.auth']
    session[:oidc_id_token] = auth&.credentials&.id_token

    super
    sync_role_from_token(current_user, auth)
  end

  private

  ROLE_PRIORITY = { 'teacher' => 'Admin', 'tutor' => 'Moderator', 'student' => 'User' }.freeze

  def sync_role_from_token(user, auth)
    return unless user && auth

    raw   = auth.extra&.raw_info || {}
    roles = Array(raw['roles'])

    role_name = ROLE_PRIORITY.find { |ldap_role, _| roles.include?(ldap_role) }&.last || 'User'
    role      = UserRole.find_by(name: role_name)

    user.update_column(:role_id, role.id) if role && user.role_id != role.id
  end
end

Rails.application.config.to_prepare do
  Auth::OmniauthCallbacksController.prepend(OidcRoleSync)
end
