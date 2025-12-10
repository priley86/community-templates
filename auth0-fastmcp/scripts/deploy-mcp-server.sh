#!/bin/bash
set -e

# Deployment script for FastMCP Server to Google Cloud Run

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
echo -e "${BLUE}  FastMCP Server Cloud Run Deployment${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Load production environment variables
ENV_FILE="$PROJECT_ROOT/.env.production"
if [ -f "$ENV_FILE" ]; then
    echo -e "${BLUE}Loading environment variables from $ENV_FILE${NC}"
    source "$ENV_FILE"
else
    echo -e "${YELLOW}Warning: $ENV_FILE not found${NC}"
    echo "Create it from .env.example or set environment variables manually"
    echo ""
fi

# Configuration
PROJECT_ID="${GCP_PROJECT_ID}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-mcp-server}"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Check required environment variables
REQUIRED_VARS=("GCP_PROJECT_ID" "AUTH0_DOMAIN" "AUTH0_AUDIENCE")

for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: ${var} is not set${NC}"
        echo "Set it in .env.production or export ${var}='your-value'"
        exit 1
    fi
done

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
cd "$PROJECT_ROOT"
gcloud builds submit --tag ${IMAGE_NAME} .

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to build container image${NC}"
    exit 1
fi

# Prepare environment variables for deployment
ENV_VARS="AUTH0_DOMAIN=${AUTH0_DOMAIN},AUTH0_AUDIENCE=${AUTH0_AUDIENCE}"

# Add optional environment variables if set
if [ -n "${MCP_SERVER_URL}" ]; then
    ENV_VARS="${ENV_VARS},MCP_SERVER_URL=${MCP_SERVER_URL}"
fi

if [ -n "${DEBUG}" ]; then
    ENV_VARS="${ENV_VARS},DEBUG=${DEBUG}"
fi

if [ -n "${CORS_ORIGINS}" ]; then
    ENV_VARS="${ENV_VARS},CORS_ORIGINS=${CORS_ORIGINS}"
fi

# Deploy to Cloud Run
echo -e "${BLUE}Deploying to Cloud Run...${NC}"
gcloud run deploy ${SERVICE_NAME} \
  --image ${IMAGE_NAME} \
  --platform managed \
  --region ${REGION} \
  --allow-unauthenticated \
  --port 3001 \
  --memory 512Mi \
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
echo -e "${GREEN}MCP Server URL:${NC}"
echo -e "${YELLOW}${SERVICE_URL}${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo ""
echo "1. Test your deployment:"
echo -e "   ${YELLOW}curl ${SERVICE_URL}/.well-known/oauth-protected-resource${NC}"
echo ""
echo "2. Update your .env.production with the deployed URL:"
echo -e "   ${YELLOW}MCP_SERVER_URL=${SERVICE_URL}${NC}"
echo ""
echo "3. Configure your MCP client to use:"
echo -e "   ${YELLOW}${SERVICE_URL}/mcp${NC}"
echo ""
echo "4. If you need to update the MCP_SERVER_URL, redeploy:"
echo -e "   ${YELLOW}./scripts/deploy-mcp-server.sh${NC}"
echo ""
echo -e "${BLUE}Useful Commands:${NC}"
echo ""
echo "View logs:"
echo -e "   ${YELLOW}gcloud run services logs ${SERVICE_NAME} --region ${REGION}${NC}"
echo ""
echo "View service details:"
echo -e "   ${YELLOW}gcloud run services describe ${SERVICE_NAME} --region ${REGION}${NC}"
