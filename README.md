# Day 11: Mastering Terraform Conditionals

This repository contains my Day 11 work for the 30-Day Terraform Challenge.  
The focus is conditionals: environment-aware locals, optional resources with `count`, safe output references for optional resources, and conditional VPC selection/creation.

## What I changed

- Refactored the webserver module to make `environment` the main decision driver.
- Centralized conditional decisions in `locals.tf`:
  - `is_production`
  - `instance_type`
  - `min_size`
  - `max_size`
  - `monitoring_enabled`
- Added optional resources with `count = condition ? 1 : 0`:
  - `aws_autoscaling_policy.scale_out`
  - `aws_cloudwatch_metric_alarm.high_cpu`
  - `aws_route53_record.alb`
- Added safe optional output references using index + conditional:
  - `local.monitoring_enabled ? aws_cloudwatch_metric_alarm.high_cpu[0].arn : null`
- Added conditional data-source/resource pattern for VPC mode:
  - Use existing VPC (`data.aws_vpc.existing`) when enabled
  - Create new VPC + subnets when disabled

## Repository structure

- `modules/services/webserver-cluster/` — conditionals-first reusable module
- `live/dev/services/webserver-cluster/` — dev deployment (environment = `dev`)
- `live/production/services/webserver-cluster/` — production deployment (environment = `production`)

## VS Code workflow

Open `terraform-challenge-day11` as the workspace root.

Run in integrated terminal:

```powershell
cd C:\Users\felix\terraform-challenge-day11\live\dev\services\webserver-cluster
terraform init
terraform validate
terraform plan
```

```powershell
cd C:\Users\felix\terraform-challenge-day11\live\production\services\webserver-cluster
terraform init
terraform validate
terraform plan
```

## Expected behavior

- Dev (`environment = "dev"`) resolves to smaller sizing (`t2.micro`, min 1, max 3).
- Production (`environment = "production"`) resolves to larger sizing (`t2.medium`, min 3, max 10).
- Turning conditional toggles on/off changes whether optional resources exist in plan.

## Requirements

- Terraform `>= 1.0`
- AWS Provider `~> 5.0`
- AWS credentials configured locally

---

Repository URL: `https://github.com/nahorfelix/terraform-challenge-day11`
