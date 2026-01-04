FROM python:3.11-slim

# Install Nginx and gettext-base (for envsubst)
RUN apt-get update && apt-get install -y nginx gettext-base && rm -rf /var/lib/apt/lists/*

# Set up Python application
WORKDIR /app
COPY api/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY api/ .

# Set up Nginx
# Remove default config
RUN rm /etc/nginx/sites-enabled/default
# Copy our config template
COPY nginx.conf /etc/nginx/conf.d/default.conf.template

# Copy Flutter build output
# Note: This assumes 'web/build/web' exists in the build context.
# The deploy script must run 'flutter build web' before building the Docker image.
COPY web/build/web /usr/share/nginx/html

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Environment variables
ENV PORT=8080

ENTRYPOINT ["/entrypoint.sh"]
