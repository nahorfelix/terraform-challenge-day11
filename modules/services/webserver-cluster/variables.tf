variable "cluster_name" {
  description = "Prefix for named resources in this stack"
  type        = string
}

variable "environment" {
  description = "Deployment environment: dev, staging, or production"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "Environment must be dev, staging, or production."
  }
}

variable "server_port" {
  description = "Application port behind the ALB"
  type        = number
  default     = 8080
}

variable "enable_autoscaling" {
  description = "Create autoscaling policy resources"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed monitoring resources (CloudWatch alarm)"
  type        = bool
  default     = false
}

variable "create_dns_record" {
  description = "Create Route53 alias record for the ALB"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "FQDN for the optional Route53 alias (required when create_dns_record is true)"
  type        = string
  default     = ""
}

variable "route53_zone_name" {
  description = "Hosted zone name for Route53 lookup, e.g. example.com."
  type        = string
  default     = ""
}

variable "use_existing_vpc" {
  description = "Use an existing VPC when true; create a new VPC when false"
  type        = bool
  default     = true
}

variable "existing_vpc_name" {
  description = "Tag Name of existing VPC when use_existing_vpc is true"
  type        = string
  default     = "existing-vpc"
}

variable "new_vpc_cidr" {
  description = "CIDR for newly created VPC when use_existing_vpc is false"
  type        = string
  default     = "10.42.0.0/16"
}

variable "custom_tags" {
  description = "Extra tags on resources"
  type        = map(string)
  default     = {}
}
