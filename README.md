# Sample application

H2 Console: http://localhost:8080/h2-console
Swagger: http://localhost:8080/swagger-ui/index.html

# Build

./gradlew awsDeploy

# Run Docker locally

./run-local.sh

# Deployment

# Deploy just the ECR repository
./deploy.sh

# Deploy both ECR and ECS with Fargate
./deploy.sh --ecs

# Deploy both ECR and ECS with Fargate and New Relic monitoring
./terraform/deploy.sh --ecs --new-relic-key "your-actual-new-relic-license-key"

# Show help information
./deploy.sh --help

# Terraform deployment

1. Authenticate Docker to your ECR repository:
   aws ecr get-login-password --region $(terraform output -raw aws_region 2>/dev/null || echo "us-east-1") | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url | cut -d'/' -f1)
2. Build your Docker image:
   docker build -t tennis-player-rest .
3. Tag your Docker image:
   docker tag tennis-player-rest:latest $(terraform output -raw ecr_repository_url):latest
4. Push your Docker image to ECR:
   docker push $(terraform output -raw ecr_repository_url):latest

To update the ECS service with a new image version:
1. After pushing a new image, force a new deployment:
   aws ecs update-service --cluster $(terraform output -raw ecs_cluster_name) --service $(terraform output -raw ecs_service_name) --force-new-deployment --region $(terraform output -raw aws_region 2>/dev/null || echo "us-east-1")



