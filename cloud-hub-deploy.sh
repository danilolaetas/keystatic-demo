#!/bin/bash

# Keystatic Demo - Cloud Hub Deploy Script
# For continuous deployment to an existing Cloud Hub service

if [ -z "$BASH_VERSION" ]; then
    echo "This script requires bash. Please run with: bash $0" >&2
    exit 1
fi

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ "${LANG:-}" == *UTF-8* ]] || [[ "${LC_ALL:-}" == *UTF-8* ]] || [[ "${LC_CTYPE:-}" == *UTF-8* ]]; then
    SYM_OK="✓"; SYM_FAIL="✗"; SYM_INFO="ℹ"; SYM_WARN="⚠"; SYM_BORDER="═"; SYM_ARROW="▶"
else
    SYM_OK="[OK]"; SYM_FAIL="[FAIL]"; SYM_INFO="[i]"; SYM_WARN="[!]"; SYM_BORDER="="; SYM_ARROW=">"
fi

print_success() { printf "${GREEN}%s %s${NC}\n" "$SYM_OK" "$1"; }
print_error()   { printf "${RED}%s %s${NC}\n" "$SYM_FAIL" "$1"; }
print_info()    { printf "${BLUE}%s %s${NC}\n" "$SYM_INFO" "$1"; }
print_warning() { printf "${YELLOW}%s %s${NC}\n" "$SYM_WARN" "$1"; }

print_header() {
    local border=$(printf '%0.s'"$SYM_BORDER" {1..51})
    printf "\n${CYAN}%s${NC}\n" "$border"
    printf "${CYAN}  %s${NC}\n" "$1"
    printf "${CYAN}%s${NC}\n\n" "$border"
}

print_step() {
    printf "\n${BLUE}%s %s${NC}\n" "$SYM_ARROW" "$1"
}

print_header "Keystatic Demo - Cloud Hub Deploy"

# Check prerequisites
print_step "Checking Prerequisites"

if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed"
    exit 1
fi

if ! docker info &> /dev/null; then
    print_error "Docker daemon is not running"
    exit 1
fi
print_success "Docker is ready"

# Load existing .env if present
if [ -f .env ]; then
    print_info "Loading existing .env configuration"
    set -a
    source .env
    set +a
fi

# Step 1: Cloud Hub Configuration
print_step "Step 1: Cloud Hub Configuration"
echo ""

# Repository ID
if [ -n "$REPOSITORY_ID" ]; then
    print_info "Current Repository ID: ${REPOSITORY_ID}"
    read -p "Repository ID [${REPOSITORY_ID}]: " INPUT_REPO_ID
    REPOSITORY_ID=${INPUT_REPO_ID:-$REPOSITORY_ID}
else
    read -p "Repository ID: " REPOSITORY_ID
    if [ -z "$REPOSITORY_ID" ]; then
        print_error "Repository ID is required"
        exit 1
    fi
fi
print_success "Repository ID: ${REPOSITORY_ID}"

# Service name (for image tag)
if [ -n "$SERVICE_NAME" ]; then
    print_info "Current Service Name: ${SERVICE_NAME}"
    read -p "Service Name [${SERVICE_NAME}]: " INPUT_SERVICE
    SERVICE_NAME=${INPUT_SERVICE:-$SERVICE_NAME}
else
    read -p "Service Name [keystatic-demo]: " SERVICE_NAME
    SERVICE_NAME=${SERVICE_NAME:-"keystatic-demo"}
fi
print_success "Service Name: ${SERVICE_NAME}"

# Step 2: Robot Credentials
print_step "Step 2: Robot Credentials"
echo ""

if [ -n "$ROBOT_USERNAME" ]; then
    print_info "Current Robot: ${ROBOT_USERNAME}"
    read -p "Use existing robot credentials? [Y/n]: " USE_EXISTING_ROBOT
    USE_EXISTING_ROBOT=${USE_EXISTING_ROBOT:-y}
fi

if [[ ! $USE_EXISTING_ROBOT =~ ^[Yy]$ ]] || [ -z "$ROBOT_USERNAME" ]; then
    read -p "Robot Username (robot\$repo+name): " ROBOT_USERNAME
    if [ -z "$ROBOT_USERNAME" ]; then
        print_error "Robot username is required"
        exit 1
    fi
    read -sp "Robot Secret: " ROBOT_SECRET
    echo ""
    if [ -z "$ROBOT_SECRET" ]; then
        print_error "Robot secret is required"
        exit 1
    fi
fi
print_success "Robot credentials configured"

# Step 3: Site URL
print_step "Step 3: Site URL"
echo ""

if [ -n "$SITE_URL" ]; then
    print_info "Current Site URL: ${SITE_URL}"
fi
read -p "Site URL [${SITE_URL:-https://${SERVICE_NAME}.pantaris.io}]: " INPUT_SITE_URL
SITE_URL=${INPUT_SITE_URL:-${SITE_URL:-"https://${SERVICE_NAME}.pantaris.io"}}
print_success "Site URL: ${SITE_URL}"

# Step 4: Artifactory Token
print_step "Step 4: Artifactory Token"
echo ""

if [ -n "$ARTIFACTORY_TOKEN" ]; then
    print_info "Artifactory token found in .env"
    read -p "Use existing token? [Y/n]: " USE_EXISTING_TOKEN
    USE_EXISTING_TOKEN=${USE_EXISTING_TOKEN:-y}
fi

if [[ ! $USE_EXISTING_TOKEN =~ ^[Yy]$ ]] || [ -z "$ARTIFACTORY_TOKEN" ]; then
    read -sp "Artifactory Token: " ARTIFACTORY_TOKEN
    echo ""
    if [ -z "$ARTIFACTORY_TOKEN" ]; then
        print_error "Artifactory token is required for @calponia packages"
        exit 1
    fi
fi
print_success "Artifactory token configured"

# Build image name
IMAGE_NAME="docker.pantaris.io/${REPOSITORY_ID}/${SERVICE_NAME}:latest"

# Summary
print_header "Summary"
echo "Repository ID:  ${REPOSITORY_ID}"
echo "Service Name:   ${SERVICE_NAME}"
echo "Site URL:       ${SITE_URL}"
echo "Image:          ${IMAGE_NAME}"
echo "Robot:          ${ROBOT_USERNAME}"
echo ""

read -p "Proceed with build and push? [Y/n]: " CONFIRM
CONFIRM=${CONFIRM:-y}

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    print_error "Cancelled."
    exit 0
fi

# Generate KEYSTATIC_SECRET if not set
if [ -z "$KEYSTATIC_SECRET" ]; then
    KEYSTATIC_SECRET=$(openssl rand -hex 32 2>/dev/null || cat /dev/urandom | tr -dc 'a-f0-9' | head -c 64)
fi

# Save configuration (all values quoted for safe sourcing)
print_step "Saving configuration"
cat > .env <<EOF
# Cloud Hub Deploy Configuration
# Updated: $(date '+%Y-%m-%d %H:%M:%S')

# Service
SERVICE_NAME="${SERVICE_NAME}"
REPOSITORY_ID="${REPOSITORY_ID}"
IMAGE_NAME="${IMAGE_NAME}"

# Robot Account (single quotes to preserve $ in username)
ROBOT_USERNAME='${ROBOT_USERNAME}'
ROBOT_SECRET="${ROBOT_SECRET}"

# Site URL
SITE_URL="${SITE_URL}"

# Artifactory Token
ARTIFACTORY_TOKEN="${ARTIFACTORY_TOKEN}"

# Keystatic GitHub OAuth
KEYSTATIC_GITHUB_CLIENT_ID="${KEYSTATIC_GITHUB_CLIENT_ID:-}"
KEYSTATIC_GITHUB_CLIENT_SECRET="${KEYSTATIC_GITHUB_CLIENT_SECRET:-}"
PUBLIC_KEYSTATIC_GITHUB_APP_SLUG="${PUBLIC_KEYSTATIC_GITHUB_APP_SLUG:-}"
KEYSTATIC_SECRET="${KEYSTATIC_SECRET}"
EOF
print_success "Configuration saved to .env"

# Update docker-compose.yml
print_step "Updating docker-compose.yml"
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  ${SERVICE_NAME}:
    image: '${IMAGE_NAME}'
    container_name: ${SERVICE_NAME}
    ports:
      - '3000:3000'
    environment:
      - HOST=0.0.0.0
      - PORT=3000
      - NODE_ENV=production
      - SITE_URL=\${SITE_URL}
      - KEYSTATIC_GITHUB_CLIENT_ID=\${KEYSTATIC_GITHUB_CLIENT_ID}
      - KEYSTATIC_GITHUB_CLIENT_SECRET=\${KEYSTATIC_GITHUB_CLIENT_SECRET}
      - PUBLIC_KEYSTATIC_GITHUB_APP_SLUG=\${PUBLIC_KEYSTATIC_GITHUB_APP_SLUG}
      - KEYSTATIC_SECRET=\${KEYSTATIC_SECRET}
    restart: unless-stopped
    labels:
      - 'com.calponia.networking.0.port=3000'
EOF
print_success "docker-compose.yml updated"

# Login to registry
print_step "Logging into Cloud Hub Registry"
echo "${ROBOT_SECRET}" | docker login -u "${ROBOT_USERNAME}" --password-stdin docker.pantaris.io

if [ $? -eq 0 ]; then
    print_success "Logged into docker.pantaris.io"
else
    print_error "Failed to login"
    exit 1
fi

# Build image
print_step "Building Docker Image"
print_info "Image: ${IMAGE_NAME}"
print_warning "Building for linux/amd64..."

docker build \
    --platform linux/amd64 \
    --build-arg ARTIFACTORY_TOKEN="${ARTIFACTORY_TOKEN}" \
    --build-arg SITE_URL="${SITE_URL}" \
    -t "${IMAGE_NAME}" \
    .

if [ $? -eq 0 ]; then
    print_success "Image built successfully"
else
    print_error "Build failed"
    exit 1
fi

# Push image
print_step "Pushing to Cloud Hub Registry"

docker push "${IMAGE_NAME}"

if [ $? -eq 0 ]; then
    print_success "Image pushed: ${IMAGE_NAME}"
else
    print_error "Push failed"
    exit 1
fi

# Done
print_header "Deploy Complete"
print_success "Image: ${IMAGE_NAME}"
echo ""
print_info "Next: Create/update version in Cloud Hub and redeploy sandbox"
echo ""
