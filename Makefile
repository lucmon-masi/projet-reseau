.PHONY: setup certs generate-vapid hosts up down logs clean sync-ldap reset-demo create-user

# ── First-time setup ──────────────────────────────────────────────────────────
setup: certs generate-vapid
	@echo ""
	@echo "Setup complete. Add the following to /etc/hosts (run 'make hosts'):"
	@echo "  127.0.0.1  keycloak.reseau.local mastodon.reseau.local"
	@echo ""
	@echo "Then: make up"

# Generate TLS certificates (wildcard *.reseau.local, self-signed CA)
certs:
	@echo "==> Generating certificates..."
	@bash nginx/generate-certs.sh

# Generate Mastodon VAPID keys and patch .env.production
generate-vapid:
	@echo "==> Generating VAPID keys..."
	$(eval PRIV := $(shell docker run --rm ghcr.io/mastodon/mastodon:v4.3.3 \
		bundle exec rake mastodon:webpush:generate_vapid_key 2>/dev/null | grep VAPID_PRIVATE_KEY | cut -d= -f2))
	$(eval PUB  := $(shell docker run --rm ghcr.io/mastodon/mastodon:v4.3.3 \
		bundle exec rake mastodon:webpush:generate_vapid_key 2>/dev/null | grep VAPID_PUBLIC_KEY  | cut -d= -f2))
	@sed -i "s|^VAPID_PRIVATE_KEY=.*|VAPID_PRIVATE_KEY=$(PRIV)|" mastodon/.env.production
	@sed -i "s|^VAPID_PUBLIC_KEY=.*|VAPID_PUBLIC_KEY=$(PUB)|"    mastodon/.env.production
	@echo "    VAPID keys written to mastodon/.env.production"

# Add /etc/hosts entries (requires sudo)
hosts:
	@grep -q "keycloak.reseau.local" /etc/hosts || \
		echo "127.0.0.1  keycloak.reseau.local mastodon.reseau.local" | sudo tee -a /etc/hosts
	@echo "==> /etc/hosts updated"

# ── Docker Compose wrappers ───────────────────────────────────────────────────
up:
	docker compose up -d --build

down:
	docker compose down

logs:
	docker compose logs -f

clean:
	docker compose down -v --remove-orphans
	rm -rf nginx/certs mastodon/certs

# ── Helpers ───────────────────────────────────────────────────────────────────
sync-ldap:
	@bash scripts/sync-ldap.sh

# Crée un utilisateur LDAP interactivement et le sync dans Keycloak
create-user:
	@python3 scripts/create-user.py

# Remet à zéro pour une démo propre (supprime tous les comptes sauf admin)
reset-demo:
	@python3 scripts/reset-demo.py
