#!/bin/sh
set -eu

if [ -z "${API_PROXY_TARGET:-}" ]; then
  echo "API_PROXY_TARGET is required" >&2
  exit 1
fi

for name in VITE_AZURE_CLIENT_ID VITE_AZURE_AUTHORITY; do
  eval "value=\${$name:-}"
  if [ -z "$value" ]; then
    echo "$name is required" >&2
    exit 1
  fi
done

js_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

cat > /usr/share/nginx/html/runtime-config.js <<EOF
window.__APP_CONFIG__ = {
  VITE_AZURE_CLIENT_ID: "$(js_escape "$VITE_AZURE_CLIENT_ID")",
  VITE_AZURE_AUTHORITY: "$(js_escape "$VITE_AZURE_AUTHORITY")",
  VITE_AZURE_REDIRECT_URI: "$(js_escape "${VITE_AZURE_REDIRECT_URI:-}")"
};
EOF

envsubst '${API_PROXY_TARGET}' \
  < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'