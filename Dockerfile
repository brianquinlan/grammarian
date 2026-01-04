# Stage 1: Build the Flutter web application
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY web/ ./web/
WORKDIR /app/web
RUN flutter pub get
RUN flutter build web

# Stage 2: Setup the Python backend and Nginx
FROM python:3.11-slim

# Install Nginx
RUN apt-get update && apt-get install -y nginx curl && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY api/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copy API source code
COPY api /app/api

# Copy built Flutter assets from Stage 1
COPY --from=build /app/web/build/web /usr/share/nginx/html

# Forward Nginx logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Configure Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Remove the default site configuration if it exists
RUN rm -f /etc/nginx/sites-enabled/default

# Copy startup script
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

# Set working directory for the Python app
WORKDIR /app/api

# Expose port 8080
EXPOSE 8080

# Start the application
CMD ["/app/start.sh"]
