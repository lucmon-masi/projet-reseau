# OmniAuth 2.x requires POST by default for the request phase (CSRF protection).
# Allow GET as well so the SSO button works without Rails UJS.
OmniAuth.config.allowed_request_methods = %i[get post]
OmniAuth.config.silence_get_warning = true
