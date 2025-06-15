provider "aws" {
  region = "ap-south-1"
}

# resource "aws_ecr_repository" "node_app" {
#  name = "node-ecs-app"
#}

resource "aws_ecs_cluster" "app_cluster" {
  name = "node-app-cluster"
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_attach" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "node_task" {
  family                   = "node-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn      = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "node-app",
      image     = "476813399880.dkr.ecr.ap-south-1.amazonaws.com/ecs-node-app:latest",
      essential = true,
      portMappings = [
        {
          containerPort = 3000,
          hostPort      = 3000,
          protocol      = "tcp"
        }
      ],
      environment = [
        {
          name  = "SECRET_WORD"
          value = "rearcrocks"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "node_service" {
  name            = "node-app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  task_definition = aws_ecs_task_definition.node_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = ["subnet-032b787321e05c875", "subnet-03de246fb22173140"]
    security_groups = ["sg-0ebd8eda112c8dd0d"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "node-app"           # must match task definition
    container_port   = 3000
  }

  depends_on = [aws_lb_listener.http]
}


# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = "vpc-0858bf58d5b9a1d78" 

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ALB
resource "aws_lb" "app" {
  name               = "node-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-0ebd8eda112c8dd0d"]
  subnets = ["subnet-032b787321e05c875", "subnet-03de246fb22173140"]
}

# Target Group
resource "aws_lb_target_group" "app_tg" {
  name        = "node-app-tg"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "vpc-0858bf58d5b9a1d78" 

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.node_app_alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-south-1:476813399880:certificate/73282f7f-9d8a-4ecb-9c82-cda64f7dcb3f"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node_app_target.arn
  }
}



