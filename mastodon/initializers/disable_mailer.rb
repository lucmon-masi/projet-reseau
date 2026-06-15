# Capture all outgoing emails without sending them.
# OIDC users already bypass email confirmation; this silences
# any residual ActionMailer calls (admin notifications, etc.).
Rails.application.config.action_mailer.delivery_method = :test
