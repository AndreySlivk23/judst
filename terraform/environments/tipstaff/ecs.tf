# Create ECS cluster
resource "aws_ecs_cluster" "tipstaff_cluster" {
  name = "tipstaff_cluster"
}

# Create a task definition for the Windows container
resource "aws_ecs_task_definition" "tipstaff_ecs_task" {
  family                = "tipstaff_ecs_task"
  execution_role_arn    = aws_iam_role.app_execution.arn
  task_role_arn         = aws_iam_role.app_task.arn
  cpu                   = 256
  memory                = 1024
  container_definitions = <<TASK_DEFINITION
  [
    {
      "name": "${var.networking[0].application}",
      "image": "mcr.microsoft.com/windows:ltsc2019",
      "cpu": 256,
      "memory": 1024,
      "essential": true,
      "command": [
        "New-Item -Path C:\\inetpub\\wwwroot\\index.html -Type file -Value '<html> <head> <title>Amazon ECS Sample App</title> <style>body {margin-top: 40px; background-color: #333;} </style> </head><body> <div style=color:white;text-align:center> <h1>Amazon ECS Sample App</h1> <h2>Congratulations!</h2> <p>Your application is now running on a container in Amazon ECS.</p>'; C:\\ServiceMonitor.exe w3svc"
      ],
      "entryPoint": [
        "powershell",
        "-Command"
      ],
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp",
          "hostPort": 80
        }
      ],
      "runtimePlatform": {
        "operatingSystemFamily": "WINDOWS_SERVER_2019_CORE"
      },
      "LogConfiguration": {
        "LogDriver": "awslogs",
        "Options": {
          "awslogs-group": "${var.networking[0].application}",
          "awslogs-region": "eu-west-2",
          "awslogs-stream-prefix": "${var.networking[0].application}"
        }
      },
      "environment" : [
        {
          "name" : "DB_HOST",
          "value" : "${aws_db_instance.tipstaffdbdev.address}"
        },
        {
          "name" : "DB_PORT",
          "value" : "5432"
        },
        {
          "name" : "DB_USER",
          "value" : "${jsondecode(data.aws_secretsmanager_secret_version.db_username.secret_string)["LOCAL_DB_USERNAME"]}"
        },
        {
          "name": "DB_PASSWORD",
          "value": "${jsondecode(data.aws_secretsmanager_secret_version.db_password.secret_string)["LOCAL_DB_PASSWORD"]}"
        }
      ]
    }
  ]
  TASK_DEFINITION

  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
}

# Create a Fargate service to run the Windows container task
resource "aws_ecs_service" "tipstaff_ecs_service" {
  name = var.networking[0].application
  deployment_controller {
    type = "ECS"
  }
  cluster                           = aws_ecs_cluster.tipstaff_cluster.id
  task_definition                   = aws_ecs_task_definition.tipstaff_ecs_task.arn
  launch_type                       = "FARGATE"
  enable_execute_command            = true
  desired_count                     = 1
  health_check_grace_period_seconds = 120

  network_configuration {
    subnets          = data.aws_subnets.private-public.ids
    security_groups  = [aws_security_group.tipstaff_dev_lb_sc.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tipstaff_dev_target_group.arn
    container_name   = var.networking[0].application
    container_port   = 80
  }

}

resource "aws_iam_role" "app_execution" {
  name = "execution-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "execution-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_execution" {
  name = "execution-${var.networking[0].application}"
  role = aws_iam_role.app_execution.id

  policy = <<-EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
           "Action": [
               "logs:CreateLogStream",
               "logs:PutLogEvents",
               "ecr:GetAuthorizationToken"
           ],
           "Resource": "*",
           "Effect": "Allow"
      },
      {
            "Action": [
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage"
            ],
              "Resource": "*",
            "Effect": "Allow"
      },
      {
          "Action": [
               "secretsmanager:GetSecretValue"
           ],
          "Resource": "*",
          "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role" "app_task" {
  name = "task-${var.networking[0].application}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = merge(
    local.tags,
    {
      Name = "task-${var.networking[0].application}"
    },
  )
}

resource "aws_iam_role_policy" "app_task" {
  name = "task-${var.networking[0].application}"
  role = aws_iam_role.app_task.id

  policy = <<-EOF
  {
   "Version": "2012-10-17",
   "Statement": [
     {
       "Effect": "Allow",
       "Action": [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
       ],
       "Resource": "*"
     }
   ]
  }
  EOF
}
