data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0

  tags = {
    Name = var.existing_vpc_name
  }
}

resource "aws_vpc" "new" {
  count = var.use_existing_vpc ? 0 : 1

  cidr_block           = var.new_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge({
    Name = "${var.cluster_name}-vpc"
  }, var.custom_tags)
}

data "aws_subnets" "existing" {
  count = var.use_existing_vpc ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [local.vpc_id]
  }
}

resource "aws_subnet" "public" {
  count = var.use_existing_vpc ? 0 : 2

  vpc_id                  = local.vpc_id
  cidr_block              = cidrsubnet(var.new_vpc_cidr, 8, count.index)
  availability_zone       = count.index == 0 ? "us-east-1a" : "us-east-1b"
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${var.cluster_name}-public-${count.index + 1}"
  }, var.custom_tags)
}

resource "aws_internet_gateway" "new" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = local.vpc_id

  tags = merge({
    Name = "${var.cluster_name}-igw"
  }, var.custom_tags)
}

resource "aws_route_table" "public" {
  count  = var.use_existing_vpc ? 0 : 1
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.new[0].id
  }

  tags = merge({
    Name = "${var.cluster_name}-public-rt"
  }, var.custom_tags)
}

resource "aws_route_table_association" "public" {
  count = var.use_existing_vpc ? 0 : 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[0].id
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "node" {
  name_prefix   = "${var.cluster_name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = local.instance_type

  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name = var.cluster_name
    server_port  = var.server_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      { Name = var.cluster_name },
      var.custom_tags
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.cluster_name}-asg"
  vpc_zone_identifier = local.subnet_ids
  target_group_arns   = [aws_lb_target_group.http.arn]
  health_check_type   = "ELB"

  min_size = local.min_size
  max_size = local.max_size

  launch_template {
    id      = aws_launch_template.node.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = var.cluster_name
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.custom_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "instance" {
  name        = "${var.cluster_name}-instance"
  description = "Security group for ${var.cluster_name} instances"
  vpc_id      = local.vpc_id

  tags = merge({
    Name = "${var.cluster_name}-instance-sg"
  }, var.custom_tags)
}

resource "aws_security_group_rule" "instance_from_alb" {
  security_group_id        = aws_security_group.instance.id
  type                     = "ingress"
  from_port                = var.server_port
  to_port                  = var.server_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  description              = "Allow inbound traffic from ALB"
}

resource "aws_security_group_rule" "instance_egress_all" {
  security_group_id = aws_security_group.instance.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

resource "aws_security_group" "alb" {
  name        = "${var.cluster_name}-alb"
  description = "Security group for ${var.cluster_name} Application Load Balancer"
  vpc_id      = local.vpc_id

  tags = merge({
    Name = "${var.cluster_name}-alb-sg"
  }, var.custom_tags)
}

resource "aws_security_group_rule" "alb_http_public" {
  security_group_id = aws_security_group.alb.id
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow inbound HTTP traffic from internet"
}

resource "aws_security_group_rule" "alb_egress_all" {
  security_group_id = aws_security_group.alb.id
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

resource "aws_lb" "public" {
  name               = "${var.cluster_name}-alb"
  load_balancer_type = "application"
  subnets            = local.subnet_ids
  security_groups    = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.public.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http.arn
  }
}

resource "aws_lb_target_group" "http" {
  name     = "${var.cluster_name}-tg"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = local.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_autoscaling_policy" "scale_out" {
  count = local.autoscaling_enabled ? 1 : 0

  name                   = "${var.cluster_name}-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = local.monitoring_enabled ? 1 : 0

  alarm_name          = "${var.cluster_name}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "CPU utilization exceeded 80%"
  alarm_actions       = local.autoscaling_enabled ? [aws_autoscaling_policy.scale_out[0].arn] : []

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web.name
  }
}

data "aws_route53_zone" "primary" {
  count = var.create_dns_record ? 1 : 0
  name  = var.route53_zone_name
}

resource "aws_route53_record" "alb" {
  count = var.create_dns_record ? 1 : 0

  zone_id = data.aws_route53_zone.primary[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.public.dns_name
    zone_id                = aws_lb.public.zone_id
    evaluate_target_health = true
  }
}
