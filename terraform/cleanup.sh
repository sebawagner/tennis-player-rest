#!/bin/bash

# Script to selectively destroy Terraform resources except ECR repository
# Created: August 3, 2025

set -e

# Text formatting
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${BOLD}${BLUE}=== Tennis Player REST API - Selective Terraform Cleanup ===${NC}\n"

# Check for AWS CLI and required environment variables
echo -e "${BOLD}Checking prerequisites...${NC}"

# Check for AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI is not installed. Please install it first.${NC}"
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check for Terraform
if ! command -v terraform &> /dev/null; then
    echo -e "${RED}Terraform is not installed. Please install it first.${NC}"
    echo "Visit: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    exit 1
fi

# Parse command-line arguments
FORCE=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --force) FORCE=true ;;
        --help)
            echo -e "\n${BOLD}Usage:${NC}"
            echo -e "  ./cleanup.sh [OPTIONS]"
            echo -e "\n${BOLD}Options:${NC}"
            echo -e "  --force    Skip confirmation prompt"
            echo -e "  --help     Show this help message"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Change to the terraform directory
cd "$(dirname "$0")"

echo -e "\n${BOLD}${BLUE}Preparing to remove all Terraform resources except ECR repository...${NC}"

# Initialize Terraform
echo -e "\n${BOLD}Initializing Terraform...${NC}"
terraform init

# Check if we can get the ECR repository name
ECR_REPO_NAME=""
ECR_REPO_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
if [ -n "$ECR_REPO_URL" ]; then
    ECR_REPO_NAME=$(echo $ECR_REPO_URL | awk -F'/' '{print $2}')
    echo -e "${GREEN}Found ECR repository: ${ECR_REPO_NAME}${NC}"
else
    echo -e "${YELLOW}Warning: Could not determine ECR repository name from Terraform output.${NC}"
    echo -e "This script will attempt to preserve any ECR repositories, but please verify manually."
fi

# Create a temporary tfvars file to disable ECS deployment
echo 'desired_count = 0' > terraform.tfvars

# Generate a plan to see what will be destroyed
echo -e "\n${BOLD}Generating plan for selective destroy...${NC}"
terraform plan -out=cleanup-plan -target=module.ecs -target=aws_instance.app -destroy

# Confirmation
if [ "$FORCE" != true ]; then
    echo -e "\n${RED}${BOLD}WARNING:${NC}${RED} This will remove all AWS resources created by Terraform EXCEPT the ECR repository.${NC}"
    echo -e "${RED}This action cannot be undone. Data may be lost.${NC}"
    echo -e "\n${YELLOW}Do you want to proceed with removal? (y/n)${NC}"
    read -r confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "\n${GREEN}Cleanup cancelled.${NC}"
        rm -f terraform.tfvars cleanup-plan
        exit 0
    fi
fi

# Apply the destroy plan for selected resources
echo -e "\n${BOLD}Removing AWS resources (preserving ECR repository)...${NC}"
terraform destroy -target=module.ecs

# Clean up temporary files
rm -f terraform.tfvars cleanup-plan

# Print confirmation and remaining resources
echo -e "\n${BOLD}${GREEN}Cleanup completed!${NC}"
echo -e "All AWS resources except the ECR repository have been removed."

# Get and display ECR repository info
if [ -n "$ECR_REPO_NAME" ]; then
    echo -e "\n${BOLD}Preserved ECR Repository:${NC}"
    echo -e "Repository URL: ${GREEN}${ECR_REPO_URL}${NC}"

    # Try to list images in the repository
    echo -e "\n${BOLD}Images in repository:${NC}"
    aws ecr describe-images --repository-name "$ECR_REPO_NAME" --query 'imageDetails[*].{Tag:imageTags[0],PushedAt:imagePushedAt}' --output table 2>/dev/null || echo "Unable to list images. Check permissions or repository existence."
fi

echo -e "\n${BOLD}${BLUE}To redeploy the ECS resources in the future:${NC}"
echo -e "  ${YELLOW}./deploy.sh --ecs${NC}"

echo -e "\n${BOLD}${GREEN}Cleanup complete!${NC}"
