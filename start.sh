#!/bin/bash

# Default to port 8080 if PORT is not set
PORT="${PORT:-8080}"

# Substitute the PORT in the Nginx configuration
# We look for 'listen [0-9]*;' and replace it with 'listen $PORT;'
sed -i "s/listen [0-9]*;/listen $PORT;/g" /etc/nginx/conf.d/default.conf

# Start Hypercorn in background
echo "Starting Hypercorn..."
hypercorn app:app --bind 0.0.0.0:5000 &
HYPERCORN_PID=$!

# Wait for Hypercorn to be ready
echo "Waiting for Hypercorn to start..."
# Loop until curl succeeds
while ! curl -s http://127.0.0.1:5000/ > /dev/null; do
    if ! kill -0 $HYPERCORN_PID 2>/dev/null; then
        echo "Hypercorn process died."
        exit 1
    fi
    echo "Hypercorn is not ready yet..."
    sleep 0.2
done
echo "Hypercorn is ready."

# Start Nginx in foreground
echo "Starting Nginx..."
exec nginx -g 'daemon off;'
