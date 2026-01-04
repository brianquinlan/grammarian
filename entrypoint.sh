#!/bin/bash
set -e

# Start the Python app in the background
# Using uvicorn to run the Quart app. app:app refers to the 'app' object in 'app.py'
uvicorn app:app --host 127.0.0.1 --port 8000 &

# Start Nginx in the foreground
# We need to substitute $PORT in nginx.conf because Nginx doesn't support environment variables in config natively
envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf

echo "Starting Nginx on port $PORT..."
nginx -g 'daemon off;'
