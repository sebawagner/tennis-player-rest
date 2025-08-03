#!/bin/bash

# Script to build and run the tennis-player-rest Docker container locally
# Created: August 3, 2025

set -e

IMAGE_NAME="org.nz.arrakeen/tennis-player-rest:0.0.1-SNAPSHOT"

# Run the container
echo -e "\n${BOLD}Running Docker container...${NC}"
echo -e "${YELLOW}The application will be available at http://localhost:8080${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop the container${NC}\n"

docker run --rm -p 8080:8080 ${IMAGE_NAME}
