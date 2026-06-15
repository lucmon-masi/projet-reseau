FROM ghcr.io/mastodon/mastodon:v4.3.3

USER root

# Trust the self-signed CA so Rails/Ruby can reach https://keycloak.reseau.local:8443
COPY mastodon/certs/ca.crt /usr/local/share/ca-certificates/reseau-local-ca.crt
RUN update-ca-certificates

# Inject initializers — no base image files are overwritten
COPY mastodon/initializers/oidc_role_sync.rb    /opt/mastodon/config/initializers/oidc_role_sync.rb
COPY mastodon/initializers/oidc_logout.rb       /opt/mastodon/config/initializers/oidc_logout.rb
COPY mastodon/initializers/disable_mailer.rb    /opt/mastodon/config/initializers/disable_mailer.rb
COPY mastodon/initializers/trusted_proxies.rb      /opt/mastodon/config/initializers/trusted_proxies.rb
COPY mastodon/initializers/fix_local_domain_urls.rb /opt/mastodon/config/initializers/fix_local_domain_urls.rb
COPY mastodon/initializers/omniauth_get.rb          /opt/mastodon/config/initializers/omniauth_get.rb
COPY mastodon/patches/application.html.haml         /opt/mastodon/app/views/layouts/application.html.haml
COPY mastodon/patches/content_security_policy.rb   /opt/mastodon/config/initializers/content_security_policy.rb
COPY mastodon/initializers/oidc_username_chooser.rb /opt/mastodon/config/initializers/oidc_username_chooser.rb
COPY mastodon/initializers/setup_featured_tags.rb   /opt/mastodon/config/initializers/setup_featured_tags.rb
COPY mastodon/controllers/choose_username_controller.rb /opt/mastodon/app/controllers/auth/choose_username_controller.rb
COPY mastodon/views/choose_username/show.html.haml  /opt/mastodon/app/views/auth/choose_username/show.html.haml
COPY mastodon/patches/routes.rb                     /opt/mastodon/config/routes.rb

USER mastodon
