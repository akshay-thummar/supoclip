#!/bin/bash
# SupoClip - Quick Start Script
# This script helps you start SupoClip with a single command
set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================"
echo "  SupoClip - AI Video Clipping Tool"
echo "============================================"
echo ""

# Load .env file only if it exists (optional fallback for local dev)
if [ -f .env ]; then
    echo "Found .env file — loading it as fallback for any unset variables..."
    # Export only variables that are not already set in the environment
    while IFS='=' read -r key value; do
        # Skip comments and blank lines
        [[ "$key" =~ ^#.*$ ]] && continue
        [[ -z "$key" ]] && continue
        # Strip inline comments from value
        value="${value%%#*}"
        # Strip surrounding quotes
        value="${value%\"}"
        value="${value#\"}"
        value="${value%\'}"
        value="${value#\'}"
        # Only set if not already exported in the environment
        if [ -z "${!key}" ]; then
            export "$key=$value"
        fi
    done < .env
    echo ""
else
    echo "No .env file found — reading entirely from environment variables."
    echo "(This is expected in Railway / Render / Docker deployments.)"
    echo ""
fi

# Check if required API keys are set in the environment
if [ -z "$ASSEMBLY_AI_API_KEY" ]; then
    echo -e "${YELLOW}Warning: ASSEMBLY_AI_API_KEY is not set${NC}"
    echo "Video transcription will not work without this key."
    echo "Set it as an environment variable or in a .env file."
    echo ""
fi

if [ -z "$OPENAI_API_KEY" ] && [ -z "$GOOGLE_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    if [[ "${LLM:-}" == ollama:* ]]; then
        :  # Ollama doesn't need an API key
    else
        echo -e "${YELLOW}Warning: No AI provider API key is set${NC}"
        echo "You need at least one of: OPENAI_API_KEY, GOOGLE_API_KEY, ANTHROPIC_API_KEY"
        echo "Or set LLM=ollama:<model> to use a local Ollama model."
        echo ""
    fi
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running!${NC}"
    echo "Please start Docker Desktop and try again."
    echo ""
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Error: docker-compose is not installed!${NC}"
    echo "Please install Docker Compose and try again."
    echo ""
    exit 1
fi

# Determine which docker compose command to use
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

echo -e "${GREEN}Starting SupoClip...${NC}"
echo ""

# Build and start containers, passing through all relevant env vars explicitly
echo "Building and starting Docker containers..."
echo "(This may take a few minutes on the first run)"
echo ""

# Export all required variables so docker-compose can interpolate them
# This ensures they are available even when not in a .env file
export ASSEMBLY_AI_API_KEY="${ASSEMBLY_AI_API_KEY:-}"
export OPENAI_API_KEY="${OPENAI_API_KEY:-}"
export GOOGLE_API_KEY="${GOOGLE_API_KEY:-}"
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
export LLM="${LLM:-}"
export OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-}"
export OLLAMA_API_KEY="${OLLAMA_API_KEY:-}"
export DATABASE_URL="${DATABASE_URL:-}"
export BETTER_AUTH_SECRET="${BETTER_AUTH_SECRET:-}"
export NEXT_PUBLIC_API_URL="${NEXT_PUBLIC_API_URL:-}"

$DOCKER_COMPOSE up -d --build

echo ""
echo -e "${GREEN}SupoClip is starting up!${NC}"
echo ""
echo "Services will be available at:"
echo "  - Frontend:  http://localhost:3000"
echo "  - Backend:   http://localhost:8000"
echo "  - API Docs:  http://localhost:8000/docs"
echo ""
echo "To view logs, run:"
echo "  $DOCKER_COMPOSE logs -f"
echo ""
echo "To stop all services, run:"
echo "  $DOCKER_COMPOSE down"
echo ""
echo "Waiting for services to be healthy..."

# Wait for services to be healthy
sleep 5

# Check if services are running
if $DOCKER_COMPOSE ps | grep -q "Up"; then
    echo -e "${GREEN}Services are starting successfully!${NC}"
    echo ""
    echo "You can now:"
    echo "  1. Open http://localhost:3000 in your browser"
    echo "  2. View logs: $DOCKER_COMPOSE logs -f"
    echo "  3. Stop services: $DOCKER_COMPOSE down"
else
    echo -e "${YELLOW}Services are starting... Check logs if you encounter issues:${NC}"
    echo "  $DOCKER_COMPOSE logs -f"
fi

echo ""
echo "============================================"
