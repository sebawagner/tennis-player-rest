#!/bin/bash

# Script to deploy the tennis-player-rest infrastructure using Terraform
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
echo -e "${BOLD}${BLUE}=== Tennis Player REST API - Terraform Deployment ===${NC}\n"

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

# Print environment variables that need to be set
echo -e "\n${BOLD}${YELLOW}Required AWS environment variables:${NC}"
echo -e "  ${BOLD}AWS_ACCESS_KEY_ID${NC} - Your AWS access key"
echo -e "  ${BOLD}AWS_SECRET_ACCESS_KEY${NC} - Your AWS secret key"
echo -e "  ${BOLD}AWS_SESSION_TOKEN${NC} - Your AWS session token (if using temporary credentials)"

# Parse command-line arguments
DEPLOY_ECS=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --ecs) DEPLOY_ECS=true ;;
        --help)
            echo -e "\n${BOLD}Usage:${NC}"
            echo -e "  ./deploy.sh [OPTIONS]"
            echo -e "\n${BOLD}Options:${NC}"
            echo -e "  --ecs    Deploy both ECR and ECS (Fargate service with load balancer)"
            echo -e "  --help   Show this help message"
            exit 0
            ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if AWS credentials are configured
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
    echo -e "\n${YELLOW}Warning: AWS credentials not found in environment variables.${NC}"
    echo -e "You can set them using:"
    echo -e "  export AWS_ACCESS_KEY_ID=your_access_key"
    echo -e "  export AWS_SECRET_ACCESS_KEY=your_secret_key"
    echo -e "  export AWS_SESSION_TOKEN=your_session_token # If using temporary credentials"

    # Check if credentials are configured via AWS CLI
    if [ -f ~/.aws/credentials ] || [ -f ~/.aws/config ]; then
        echo -e "${GREEN}AWS credentials file found. Will use credentials from AWS CLI configuration.${NC}"
    else
        echo -e "${RED}No AWS credentials found. Please configure AWS credentials before running this script.${NC}"
        echo -e "You can run 'aws configure' to set up your credentials."
        exit 1
    fi
fi

# Change to the terraform directory
cd "$(dirname "$0")"

echo -e "\n${BOLD}${BLUE}Starting Terraform deployment...${NC}"

# Initialize Terraform
echo -e "\n${BOLD}Initializing Terraform...${NC}"
terraform init

# Create appropriate variable file based on whether ECS is being deployed
if [ "$DEPLOY_ECS" = true ]; then
    echo -e "\n${BOLD}${BLUE}Deploying both ECR repository and ECS Fargate service...${NC}"
else
    echo -e "\n${BOLD}${BLUE}Deploying ECR repository only...${NC}"
    # Create a temporary tfvars file to disable ECS deployment
    echo 'desired_count = 0' > terraform.tfvars
fi

# Plan the deployment
echo -e "\n${BOLD}Planning deployment...${NC}"
terraform plan -out=tfplan

# Ask for confirmation before applying
echo -e "\n${YELLOW}Do you want to apply these changes? (y/n)${NC}"
read -r confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo -e "\n${RED}Deployment cancelled.${NC}"
    # Clean up temporary tfvars if created
    [ "$DEPLOY_ECS" = false ] && rm -f terraform.tfvars
    exit 0
fi

# Apply the Terraform plan
echo -e "\n${BOLD}Applying deployment plan...${NC}"
terraform apply tfplan

# Clean up temporary tfvars if created
[ "$DEPLOY_ECS" = false ] && rm -f terraform.tfvars

# Print outputs after successful deployment
echo -e "\n${BOLD}${GREEN}Deployment completed successfully!${NC}"

# ECR repository details
echo -e "\n${BOLD}ECR Repository Details:${NC}"
echo -e "ECR Repository URL: $(terraform output -raw ecr_repository_url 2>/dev/null || echo "Not available")"

# Print ECS application URL if deployed
if [ "$DEPLOY_ECS" = true ] && terraform output application_url &>/dev/null; then
    echo -e "\n${BOLD}ECS Application Details:${NC}"
    APP_URL=$(terraform output -raw application_url)
    echo -e "Application URL: ${GREEN}${APP_URL}${NC}"
    echo -e "Note: It may take a few minutes for the application to become available."

    echo -e "\n${BOLD}ECS Cluster:${NC} $(terraform output -raw ecs_cluster_name 2>/dev/null || echo "Not available")"
    echo -e "${BOLD}ECS Service:${NC} $(terraform output -raw ecs_service_name 2>/dev/null || echo "Not available")"
fi

# Print instructions for using the ECR repository
echo -e "\n${BOLD}${BLUE}Next steps:${NC}"
echo -e "1. Authenticate Docker to your ECR repository:"
echo -e "   ${YELLOW}aws ecr get-login-password --region \$(terraform output -raw aws_region 2>/dev/null || echo \"us-east-1\") | docker login --username AWS --password-stdin \$(terraform output -raw ecr_repository_url | cut -d'/' -f1)${NC}"
echo -e "2. Build your Docker image:"
echo -e "   ${YELLOW}docker build -t tennis-player-rest .${NC}"
echo -e "3. Tag your Docker image:"
echo -e "   ${YELLOW}docker tag tennis-player-rest:latest \$(terraform output -raw ecr_repository_url):latest${NC}"
echo -e "4. Push your Docker image to ECR:"
echo -e "   ${YELLOW}docker push \$(terraform output -raw ecr_repository_url):latest${NC}"

if [ "$DEPLOY_ECS" = true ]; then
    echo -e "\n${BOLD}To update the ECS service with a new image version:${NC}"
    echo -e "1. After pushing a new image, force a new deployment:"
    echo -e "   ${YELLOW}aws ecs update-service --cluster \$(terraform output -raw ecs_cluster_name) --service \$(terraform output -raw ecs_service_name) --force-new-deployment --region \$(terraform output -raw aws_region 2>/dev/null || echo \"us-east-1\")${NC}"
else
    echo -e "\n${BOLD}To deploy the ECS service with your application:${NC}"
    echo -e "   ${YELLOW}./deploy.sh --ecs${NC}"
fi

echo -e "\n${BOLD}${GREEN}Happy deploying!${NC}"
