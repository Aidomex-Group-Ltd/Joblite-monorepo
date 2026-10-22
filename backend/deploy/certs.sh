#!/bin/sh
# Local certificate generator for the isolated release verification stack
# (compose service `certs`, runs inside the postgres:18 image where openssl
# is available and the container is still root).
#
# Writes into the shared `certs` volume:
#   ca.crt       local CA the application trusts (DATABASE_CA_CERT)
#   server.crt   PostgreSQL server certificate, SAN DNS:joblite-db
#   server.key   PostgreSQL server key (0600, owner uid 999 = container user)
#   localhost.crt/key  HTTPS certificate for the local TLS proxy (SAN localhost)
#
# Local verification only. Production must use real certificates.
set -eu

OUT=/certs
cd "$OUT"

if [ -f .generated ]; then
  echo "certs: already generated, reusing volume contents"
  exit 0
fi

echo "certs: generating local CA and service certificates"

openssl req -x509 -newkey rsa:2048 -nodes -keyout ca.key -out ca.crt -days 3650 \
  -subj "/CN=Joblite local verification CA"

# PostgreSQL server certificate; key must be owned by uid 999 (postgres user
# in the postgres:18 image) with mode 0600 or the server refuses to start.
openssl req -newkey rsa:2048 -nodes -keyout server.key -out server.csr \
  -subj "/CN=joblite-db"
printf "subjectAltName=DNS:joblite-db,DNS:localhost\n" > server.ext
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out server.crt -days 3650 -extfile server.ext

# Local TLS proxy certificate for the browser-facing https://localhost origin.
openssl req -newkey rsa:2048 -nodes -keyout localhost.key -out localhost.csr \
  -subj "/CN=localhost"
printf "subjectAltName=DNS:localhost,IP:127.0.0.1\n" > localhost.ext
openssl x509 -req -in localhost.csr -CA ca.crt -CAkey ca.key -CAcreateserial \
  -out localhost.crt -days 3650 -extfile localhost.ext

chmod 644 ca.crt server.crt localhost.crt
chmod 600 server.key localhost.key
chown 999:999 server.key server.crt ca.crt
rm -f server.csr localhost.csr server.ext localhost.ext ca.key ca.srl

touch .generated
echo "certs: done"
