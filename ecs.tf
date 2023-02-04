data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
}

resource "aws_launch_template" "example" {
  name          = local.name
  instance_type = var.instance
  image_id      = jsondecode(data.aws_ssm_parameter.ecs_optimized_ami.value)["image_id"]
  user_data     = base64encode(local.user_data)
  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  key_name = "autoscaling_ecs"
  depends_on = [
    aws_ecs_cluster.example
  ]
}

resource "aws_autoscaling_group" "example" {
  desired_capacity    = 1
  max_size            = 3
  min_size            = 1
  vpc_zone_identifier = var.subnets
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }
}

resource "aws_ecs_capacity_provider" "example" {
  name = local.name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.example.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 100
    }
  }
}

resource "aws_service_discovery_http_namespace" "example" {
  name        = "default"
  description = "example"
}

resource "aws_ecs_cluster" "example" {
  name = local.name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  configuration {
    execute_command_configuration {
      logging = "DEFAULT"
    }
  }

  service_connect_defaults {
    namespace = aws_service_discovery_http_namespace.example.arn
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name = aws_ecs_cluster.example.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT", aws_ecs_capacity_provider.example.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.example.name
  }
}

resource "aws_ecs_service" "example" {
  name            = local.name
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example.arn
  desired_count   = 15
}

resource "aws_ecs_task_definition" "example" {
  family = "httpd-task"
  container_definitions = jsonencode([
    {
      name      = "httpd-demo"
      image     = "httpd:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])


}

resource "aws_autoscaling_policy" "scaleup" {
  name                   = "scaleUp"
  # adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.example.name
  policy_type = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 80.0
  }
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 15
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.example.name}/${aws_ecs_service.example.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy" {
  name               = "scale-example"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value = 80
    predefined_metric_specification {
     predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}