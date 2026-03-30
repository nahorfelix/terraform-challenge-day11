terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name = "felix-ws-day11-production"
  environment  = "production"

  server_port                 = 8080
  enable_autoscaling          = true
  enable_detailed_monitoring  = true
  create_dns_record           = false
  use_existing_vpc            = false
  existing_vpc_name           = "existing-vpc"

  custom_tags = {
    Environment = "production"
    ManagedBy   = "terraform"
    Day         = "11"
  }
}

output "alb_dns_name" {
  value = module.webserver_cluster.alb_dns_name
}

output "effective_instance_type" {
  value = module.webserver_cluster.instance_type
}

output "asg_min_size" {
  value = module.webserver_cluster.asg_min_size
}

output "asg_max_size" {
  value = module.webserver_cluster.asg_max_size
}

output "monitoring_enabled" {
  value = module.webserver_cluster.monitoring_enabled
}
