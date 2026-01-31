#!/bin/bash

# Script to publish Kotlin Multiplatform library to Maven
# Usage:
#   ./publishMaven.sh --local   # Publish to mavenLocal
#   ./publishMaven.sh --remote  # Publish to remote Maven repository

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
PUBLISH_TYPE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --local)
            PUBLISH_TYPE="local"
            shift
            ;;
        --remote)
            PUBLISH_TYPE="remote"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--local|--remote]"
            echo ""
            echo "Options:"
            echo "  --local   Publish to mavenLocal (~/.m2/repository)"
            echo "  --remote  Publish to remote Maven repository (requires credentials)"
            echo "  --help    Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate that a publish type was specified
if [ -z "$PUBLISH_TYPE" ]; then
    echo -e "${RED}Error: No publish type specified${NC}"
    echo "Usage: $0 [--local|--remote]"
    echo "Use --help for more information"
    exit 1
fi

# Navigate to library directory
cd "$(dirname "$0")/library"

# Refresh dependencies first
echo -e "${GREEN}Refreshing dependencies...${NC}"
../gradlew build --refresh-dependencies

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Dependency refresh failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Dependencies refreshed${NC}"
echo ""

# Build the project
echo -e "${GREEN}Building project...${NC}"
../gradlew build

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build successful${NC}"
echo ""

# Execute the appropriate Gradle task
if [ "$PUBLISH_TYPE" = "local" ]; then
    echo -e "${GREEN}Publishing to mavenLocal...${NC}"
    echo -e "${YELLOW}Location: ~/.m2/repository${NC}"
    ../gradlew publishToMavenLocal
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully published to mavenLocal${NC}"
        echo -e "${YELLOW}Library can be used by adding mavenLocal() to repositories${NC}"
    else
        echo -e "${RED}✗ Failed to publish to mavenLocal${NC}"
        exit 1
    fi
    
elif [ "$PUBLISH_TYPE" = "remote" ]; then
    echo -e "${GREEN}Publishing to remote Maven repository...${NC}"
    
    # Check for required environment variables
    if [ -z "$MAVEN_USERNAME" ] || [ -z "$MAVEN_PASSWORD" ]; then
        echo -e "${YELLOW}Warning: MAVEN_USERNAME and/or MAVEN_PASSWORD not set${NC}"
        echo -e "${YELLOW}Remote publishing may fail if credentials are required${NC}"
    fi
    
    ../gradlew publishAllPublicationsToMavenRepository
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully published to remote Maven repository${NC}"
    else
        echo -e "${RED}✗ Failed to publish to remote Maven repository${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}Publication complete!${NC}"
