#!/bin/bash
# Deployment script for Grammarian to Google Cloud Run

set -e

SERVICE_NAME="grammarian"
REGION="us-central1"

# Check if PROJECT_ID is provided
if [ -z "$PROJECT_ID" ]; then
  echo "Error: PROJECT_ID environment variable is not set."
  echo "Please set it using: export PROJECT_ID=your-project-id"
  exit 1
fi

echo "----------------------------------------------------------------"
echo "Deploying $SERVICE_NAME to project $PROJECT_ID in region $REGION"
echo "----------------------------------------------------------------"

# Submit the build to Cloud Build
echo "Step 1: Building container image..."
gcloud builds submit --tag gcr.io/$PROJECT_ID/$SERVICE_NAME

# Deploy to Cloud Run
echo "Step 2: Deploying to Cloud Run..."
gcloud run deploy $SERVICE_NAME \
  --image gcr.io/$PROJECT_ID/$SERVICE_NAME \
  --region $REGION \
  --platform managed \
  --allow-unauthenticated

echo "----------------------------------------------------------------"
echo "Deployment complete!"
