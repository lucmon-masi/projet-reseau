# Mastodon hardcodes LOCAL_DOMAIN (no port) for custom_css_url and some OG image
# URLs. Since we run on port 8443, these requests fail. Redirect all generated
# URLs that use local_domain to web_domain so the port is included.
Rails.application.config.to_prepare do
  ApplicationHelper.module_eval do
    def custom_css_url
      custom_css_path(
        host:     Rails.configuration.x.web_domain,
        protocol: :https
      )
    end
  end
end
