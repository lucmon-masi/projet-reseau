# frozen_string_literal: true

require_relative '../../app/lib/content_security_policy'

policy = ContentSecurityPolicy.new
assets_host = policy.assets_host
media_hosts = policy.media_hosts

Rails.application.config.content_security_policy do |p|
  p.base_uri        :none
  p.default_src     :none
  p.frame_ancestors :none
  p.font_src        :self, assets_host
  p.img_src         :self, :data, :blob, *media_hosts
  p.media_src       :self, :data, *media_hosts
  p.manifest_src    :self, assets_host

  # Allow inline styles (React injects them dynamically; nonce alone isn't enough)
  p.style_src :self, assets_host, :unsafe_inline

  if policy.sso_host.present?
    p.form_action :self, policy.sso_host
  else
    p.form_action :self
  end

  p.child_src  :self, :blob, assets_host
  p.worker_src :self, :blob, assets_host

  p.connect_src :self, :data, :blob, *media_hosts, Rails.configuration.x.streaming_api_base_url
  # Allow inline scripts needed by Mastodon's JS bundle
  p.script_src  :self, assets_host, "'wasm-unsafe-eval'", :unsafe_inline
  p.frame_src   :self, :https
end

Rails.application.config.content_security_policy_nonce_generator = nil
Rails.application.config.content_security_policy_nonce_directives = []

Rails.application.reloader.to_prepare do
  PgHero::HomeController.content_security_policy do |p|
    p.script_src :self, :unsafe_inline, assets_host
    p.style_src  :self, :unsafe_inline, assets_host
  end
end
