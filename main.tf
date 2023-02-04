

terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.52.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  name      = "example"
  user_data = <<-EOT
    #!/bin/bash
    echo ECS_CLUSTER=example >> /etc/ecs/ecs.config;
  EOT
}

