# webserver-cluster

Environment-aware Terraform module for a webserver cluster on AWS.

It creates:
- VPC mode (conditional): either use existing VPC or create a new one
- ALB, target group, listener
- launch template + autoscaling group
- security groups and rules
- optional autoscaling policy, optional high-CPU alarm, optional DNS record

Conditionals are centralized in `locals.tf`, and optional resources use `count = condition ? 1 : 0`.
