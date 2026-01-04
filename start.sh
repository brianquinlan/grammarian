#!/bin/bash

# Default to port 8080 if PORT is not set
PORT="${PORT:-8080}"

# Substitute the PORT in the Nginx configuration
# We look for 'listen [0-9]*;' and replace it with 'listen $PORT;'
sed -i "s/listen [0-9]*;/listen $PORT;/g" /etc/nginx/conf.d/default.conf

# Start Nginx in the background
nginx

# Start the Quart app using Hypercorn
# We are binding to 0.0.0.0:5000 so the Nginx proxy can reach it via localhost:5000 (inside the container)
# and we use exec to replace the shell process
exec hypercorn app:app --bind 0.0.0.0:5000
