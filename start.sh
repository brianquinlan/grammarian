#!/bin/bash
# Start Nginx in the background
nginx

# Start the Quart app using Hypercorn
# We are binding to 0.0.0.0:5000 so the Nginx proxy can reach it via localhost:5000 (inside the container)
# and we use exec to replace the shell process
exec hypercorn app:app --bind 0.0.0.0:5000
