#!/bin/sh

set -eu

fingerprint="$(openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey |
openssl rsa -pubin -outform DER 2>/dev/null |
sha256sum |
cut -d' ' -f1)"

exec jq --compact-output -n --arg fingerprint "$fingerprint" '{"fingerprint": $fingerprint}'
