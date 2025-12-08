#!/bin/bash
set -e

# Deployment script for LangGraph Server to Google Cloud Run
# This makes your LangGraph server externally accessible

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  LangGraph Cloud Run Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Load production environment variables
ENV_FILE="$PROJECT_ROOT/backend/.env.production"
if [ -f "$ENV_FILE" ]; then
    echo -e "${BLUE}Loading environment variables from $ENV_FILE${NC}"
    source "$ENV_FILE"
else
    echo -e "${YELLOW}Warning: $ENV_FILE not found${NC}"
    echo "Create it from backend/.env.production.example or set environment variables manually"
    echo ""
fi

# Configuration
PROJECT_ID="${GCP_PROJECT_ID}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="langgraph-server"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Check required environment variables
if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}Error: GCP_PROJECT_ID is not set${NC}"
    echo "Set it in backend/.env.production or export GCP_PROJECT_ID='your-project-id'"
    exit 1
fi

if [ -z "$GOOGLE_API_KEY" ] && [ -z "$OPENAI_API_KEY" ]; then
    echo -e "${RED}Error: Neither GOOGLE_API_KEY nor OPENAI_API_KEY is set${NC}"
    echo "Set at least one in backend/.env.production"
    exit 1
fi

if [ ! -z "$GOOGLE_API_KEY" ]; then
    echo -e "${GREEN}✓ GOOGLE_API_KEY is set${NC}"
fi

if [ ! -z "$OPENAI_API_KEY" ]; then
    echo -e "${GREEN}✓ OPENAI_API_KEY is set${NC}"
fi

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}Error: gcloud CLI is not installed${NC}"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Set the project
echo -e "${BLUE}Setting GCP project to ${PROJECT_ID}...${NC}"
gcloud config set project ${PROJECT_ID}

# Enable required APIs
echo -e "${BLUE}Enabling required Google Cloud APIs...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Build the container image
echo -e "${BLUE}Building container image...${NC}"
echo "This may take a few minutes..."
cd backend

# Create a temporary cloudbuild.yaml for the custom Dockerfile
cat > /tmp/cloudbuild-langgraph.yaml <<EOF
steps:
- name: 'gcr.io/cloud-builders/docker'
  args: ['build', '-t', '${IMAGE_NAME}', '-f', 'Dockerfile.langgraph', '.']
images:
- '${IMAGE_NAME}'
EOF

gcloud builds submit --config /tmp/cloudbuild-langgraph.yaml .

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to build container image${NC}"
    rm -f /tmp/cloudbuild-langgraph.yaml
    exit 1
fi

rm -f /tmp/cloudbuild-langgraph.yaml

# Prepare environment variables for deployment
ENV_VARS=""

# Add LLM API keys
if [ ! -z "$GOOGLE_API_KEY" ]; then
    ENV_VARS="GOOGLE_API_KEY=${GOOGLE_API_KEY}"
fi

if [ ! -z "$OPENAI_API_KEY" ]; then
    if [ -z "$ENV_VARS" ]; then
        ENV_VARS="OPENAI_API_KEY=${OPENAI_API_KEY}"
    else
        ENV_VARS="${ENV_VARS},OPENAI_API_KEY=${OPENAI_API_KEY}"
    fi
fi

# Add Auth0 configuration (required for agent tools)
if [ ! -z "$AUTH0_DOMAIN" ]; then
    ENV_VARS="${ENV_VARS},AUTH0_DOMAIN=${AUTH0_DOMAIN}"
fi

if [ ! -z "$AUTH0_CLIENT_ID" ]; then
    ENV_VARS="${ENV_VARS},AUTH0_CLIENT_ID=${AUTH0_CLIENT_ID}"
fi

if [ ! -z "$AUTH0_CLIENT_SECRET" ]; then
    ENV_VARS="${ENV_VARS},AUTH0_CLIENT_SECRET=${AUTH0_CLIENT_SECRET}"
fi

# Add optional environment variables if set
if [ ! -z "$LANGCHAIN_API_KEY" ]; then
    ENV_VARS="${ENV_VARS},LANGCHAIN_API_KEY=${LANGCHAIN_API_KEY}"
fi

if [ ! -z "$LANGCHAIN_TRACING_V2" ]; then
    ENV_VARS="${ENV_VARS},LANGCHAIN_TRACING_V2=${LANGCHAIN_TRACING_V2}"
fi

# Deploy to Cloud Run
echo -e "${BLUE}Deploying to Cloud Run...${NC}"
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --port 54367 \
  --memory 1Gi \
  --cpu 1 \
  --timeout 300 \
  --max-instances 10 \
  --set-env-vars "${ENV_VARS}"

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to deploy to Cloud Run${NC}"
    exit 1
fi

# Get the service URL
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --region ${REGION} --format 'value(status.url)')

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  ✓ Deployment Successful!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${GREEN}LangGraph Server URL:${NC}"
echo -e "${YELLOW}${SERVICE_URL}${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Update your backend/.env.production file with:"
echo -e "   ${YELLOW}LANGGRAPH_EXTERNAL_URL=${SERVICE_URL}${NC}"
echo ""
echo "2. Test your deployment:"
echo -e "   ${YELLOW}curl ${SERVICE_URL}/health${NC}"
echo ""
echo "3. View logs:"
echo -e "   ${YELLOW}gcloud run services logs ${SERVICE_NAME} --region ${REGION}${NC}"
echo ""
echo "4. Monitor in Cloud Console:"
echo -e "   ${YELLOW}https://console.cloud.google.com/run/detail/${REGION}/${SERVICE_NAME}/metrics${NC}"
echo ""
