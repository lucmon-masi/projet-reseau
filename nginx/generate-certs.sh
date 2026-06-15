#!/usr/bin/env bash
set -euo pipefail

CERTS_DIR="$(dirname "$0")/certs"
mkdir -p "$CERTS_DIR"

echo "==> Generating CA key and certificate..."
openssl genrsa -out "$CERTS_DIR/ca.key" 4096

openssl req -new -x509 -days 3650 -key "$CERTS_DIR/ca.key" \
  -out "$CERTS_DIR/ca.crt" \
  -subj "/C=FR/O=Reseau Local/CN=Reseau Local CA"

echo "==> Generating server key..."
openssl genrsa -out "$CERTS_DIR/reseau.local.key" 2048

echo "==> Generating CSR with SANs..."
openssl req -new -key "$CERTS_DIR/reseau.local.key" \
  -out "$CERTS_DIR/reseau.local.csr" \
  -subj "/C=FR/O=Reseau Local/CN=*.reseau.local"

cat > "$CERTS_DIR/san.ext" <<EOF
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
subjectAltName = @alt_names

[alt_names]
DNS.1 = *.reseau.local
DNS.2 = reseau.local
DNS.3 = keycloak.reseau.local
DNS.4 = mastodon.reseau.local
EOF

echo "==> Signing server certificate with CA..."
openssl x509 -req -days 3650 \
  -in "$CERTS_DIR/reseau.local.csr" \
  -CA "$CERTS_DIR/ca.crt" \
  -CAkey "$CERTS_DIR/ca.key" \
  -CAcreateserial \
  -out "$CERTS_DIR/reseau.local.crt" \
  -extensions v3_req \
  -extfile "$CERTS_DIR/san.ext"

cp "$CERTS_DIR/ca.crt" mastodon/certs/ca.crt

echo "==> Certificates written to $CERTS_DIR"
echo "    ca.crt              → shared with Mastodon container"
echo "    reseau.local.crt    → nginx TLS certificate"
echo "    reseau.local.key    → nginx TLS private key"
