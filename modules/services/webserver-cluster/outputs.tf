output "alb_dns_name" {
  value       = aws_lb.public.dns_name
  description = "The domain name of the load balancer"
}

output "alb_arn" {
  value       = aws_lb.public.arn
  description = "The ARN of the load balancer"
}

output "alb_zone_id" {
  value       = aws_lb.public.zone_id
  description = "The hosted zone ID of the load balancer"
}

output "asg_name" {
  value       = aws_autoscaling_group.web.name
  description = "The name of the Auto Scaling Group"
}

output "asg_arn" {
  value       = aws_autoscaling_group.web.arn
  description = "The ARN of the Auto Scaling Group"
}

output "launch_template_id" {
  value       = aws_launch_template.node.id
  description = "The ID of the launch template"
}

output "target_group_arn" {
  value       = aws_lb_target_group.http.arn
  description = "The ARN of the target group"
}

output "alb_security_group_id" {
  value       = aws_security_group.alb.id
  description = "The ID of the ALB security group"
}

output "instance_security_group_id" {
  value       = aws_security_group.instance.id
  description = "The ID of the instance security group"
}

output "vpc_id" {
  value       = local.vpc_id
  description = "The ID of the VPC where resources are created"
}

output "subnet_ids" {
  value       = local.subnet_ids
  description = "The IDs of the subnets where resources are created"
}

output "environment" {
  value       = var.environment
  description = "Deployment environment used by conditional logic"
}

output "instance_type" {
  value       = local.instance_type
  description = "Instance type resolved from environment"
}

output "asg_min_size" {
  value       = local.min_size
  description = "Resolved ASG minimum size"
}

output "asg_max_size" {
  value       = local.max_size
  description = "Resolved ASG maximum size"
}

output "autoscaling_enabled" {
  value       = local.autoscaling_enabled
  description = "Whether autoscaling policy creation is enabled"
}

output "monitoring_enabled" {
  value       = local.monitoring_enabled
  description = "Whether detailed monitoring resources are enabled"
}

output "scale_out_policy_arn" {
  value       = local.autoscaling_enabled ? aws_autoscaling_policy.scale_out[0].arn : null
  description = "ARN of scale out policy if created"
}

output "high_cpu_alarm_arn" {
  value       = local.monitoring_enabled ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null
  description = "ARN of high CPU alarm if created"
}

output "dns_record_fqdn" {
  value       = var.create_dns_record ? aws_route53_record.alb[0].fqdn : null
  description = "Route53 record fqdn when DNS record is created"
}

output "use_existing_vpc" {
  value       = var.use_existing_vpc
  description = "Whether existing VPC mode is enabled"
}
