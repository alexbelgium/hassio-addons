#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# ==============================================================================
# Home Assistant Add-on: Omni Tools
# Starts omni-tools
# ==============================================================================

bashio::log.info "Starting omni-tools..."

# Create nginx configuration
mkdir -p /etc/nginx/http.d

cat > /etc/nginx/http.d/default.conf << 'EOF'
server {
    listen 8080;
    server_name _;
    
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Start nginx
nginx

# Start omni-tools container content
exec docker run -d --name omni-tools-app --restart unless-stopped -p 80:80 iib0011/omni-tools:latest