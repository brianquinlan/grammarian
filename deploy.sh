#!/bin/bash
set -e

# Check environment variables
if [ -z "$GOOGLE_CLOUD_PROJECT" ]; then
  echo "Error: GOOGLE_CLOUD_PROJECT environment variable is not set."
  exit 1
fi

if [ -z "$GOOGLE_CLOUD_REGION" ]; then
  echo "Error: GOOGLE_CLOUD_REGION environment variable is not set."
  exit 1
fi

echo "Deploying to Project: $GOOGLE_CLOUD_PROJECT, Region: $GOOGLE_CLOUD_REGION"

# Build Flutter Web App
echo "Building Flutter Web App..."
cd web
flutter build web
cd ..

# Check if build was successful
if [ ! -d "web/build/web" ]; then
    echo "Error: Flutter build failed. web/build/web directory not found."
    exit 1
fi

IMAGE_NAME="gcr.io/$GOOGLE_CLOUD_PROJECT/grammarian"

# Build Container using Cloud Build
echo "Building Container Image..."
gcloud builds submit --tag "$IMAGE_NAME" .

# Deploy to Cloud Run
echo "Deploying to Cloud Run..."
gcloud run deploy grammarian \
  --image "$IMAGE_NAME" \
  --region "$GOOGLE_CLOUD_REGION" \
  --platform managed \
  --allow-unauthenticated \
  --set-secrets="GOOGLE_API_KEY=GOOGLE_API_KEY:latest"

echo "Deployment complete!"
