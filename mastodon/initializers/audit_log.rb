# frozen_string_literal: true

# Audit log — enregistre les connexions et déconnexions dans les logs Rails.
# Les lignes [AUDIT] sont facilement filtrables : grep '\[AUDIT\]' production.log

module AuditLog
  AUDIT_LOGGER = Logger.new($stdout).tap { |l| l.formatter = proc { |_, t, _, msg| "#{t.iso8601} #{msg}\n" } }

  def self.log(event, user: nil, request: nil)
    ip  = request&.remote_ip || 'unknown'
    uid = user ? "#{user.account&.username}(#{user.id})" : 'anonymous'
    AUDIT_LOGGER.info("[AUDIT] event=#{event} user=#{uid} ip=#{ip}")
  end
end

# Hook sur le login
ActiveSupport::Notifications.subscribe('action_controller.devise.sessions.create') do |*args|
  # Covered by OmniAuth callback below
end

Rails.application.config.to_prepare do
  # Login via OmniAuth (SSO Keycloak)
  Auth::OmniauthCallbacksController.class_eval do
    after_action :audit_login, only: [:openid_connect]

    private

    def audit_login
      AuditLog.log('LOGIN_SSO', user: current_user, request: request) if current_user
    end
  end

  # Logout
  Auth::SessionsController.class_eval do
    after_action :audit_logout, only: [:destroy]

    private

    def audit_logout
      AuditLog.log('LOGOUT', request: request)
    end
  end
end
