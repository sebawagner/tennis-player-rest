resource "aws_ecs_cluster" "tennis_player_cluster" {
  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = var.tags
}

# Create a VPC for the ECS service
resource "aws_vpc" "ecs_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-vpc"
  })
}

# Create public subnets for the load balancer
resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-public-subnet-${count.index + 1}"
  })
}

# Create private subnets for the ECS tasks
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.ecs_vpc.id
  cidr_block        = "10.0.${count.index + 101}.0/24"
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-private-subnet-${count.index + 1}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.ecs_vpc.id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-igw"
  })
}

# Create NAT Gateway for private subnets
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-eip"
  })
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-nat"
  })

  depends_on = [aws_internet_gateway.igw]
}

# Route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-public-rt"
  })
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ecs_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-private-rt"
  })
}

# Route table associations
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-alb-sg"
  })
}

# Security group for ECS tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.cluster_name}-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = aws_vpc.ecs_vpc.id

  ingress {
    description     = "Allow access from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.cluster_name}-tasks-sg"
  })
}

# Application Load Balancer
resource "aws_lb" "tennis_player_alb" {
  name               = "${var.cluster_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = var.tags
}

# Target group for ALB
resource "aws_lb_target_group" "tennis_player" {
  name        = "${var.cluster_name}-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.ecs_vpc.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    matcher             = "200-399"
  }

  tags = var.tags
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.tennis_player_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tennis_player.arn
  }
}

# ECS task execution role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Attach the ECS task execution policy
resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Create custom policy for CloudWatch Logs
resource "aws_iam_policy" "cloudwatch_logs_policy" {
  name        = "${var.cluster_name}-cloudwatch-logs-policy"
  description = "Policy to allow creation and management of CloudWatch log groups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${var.cluster_name}*",
          "arn:aws:logs:${var.aws_region}:*:log-group:/ecs/${var.cluster_name}*:log-stream:*"
        ]
      }
    ]
  })

  tags = var.tags
}

# Attach CloudWatch Logs policy to the task execution role
resource "aws_iam_role_policy_attachment" "ecs_cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_policy.arn
}

# Task definition for the service
resource "aws_ecs_task_definition" "tennis_player" {
  family                   = "${var.cluster_name}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "tennis-player-rest"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.cluster_name}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])

  tags = var.tags
}

# ECS service
resource "aws_ecs_service" "tennis_player" {
  name            = "${var.cluster_name}-service"
  cluster         = aws_ecs_cluster.tennis_player_cluster.id
  task_definition = aws_ecs_task_definition.tennis_player.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tennis_player.arn
    container_name   = "tennis-player-rest"
    container_port   = 8080
  }

  depends_on = [
    aws_lb_listener.front_end,
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
  ]

  tags = var.tags
}
