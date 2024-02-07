#!/bin/sh

exec jq --compact-output -n --arg content "$(sudo base64 -w0 /etc/kubernetes/admin.conf)" '{"content":$content}'
