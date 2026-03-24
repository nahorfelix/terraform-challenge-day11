locals {
  is_production = var.environment == "production"

  instance_type = local.is_production ? "t2.medium" : "t2.micro"
  min_size      = local.is_production ? 3 : 1
  max_size      = local.is_production ? 10 : 3

  monitoring_enabled  = local.is_production || var.enable_detailed_monitoring
  autoscaling_enabled = var.enable_autoscaling

  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.new[0].id

  subnet_ids = var.use_existing_vpc ? data.aws_subnets.existing[0].ids : aws_subnet.public[*].id
}
