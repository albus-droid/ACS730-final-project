# Create the Application Load Balancer
resource "aws_lb" "this" {
  name               = var.name
  internal           = false
  load_balancer_type = var.load_balancer_type
  subnets            = var.subnet_ids
  security_groups    = var.security_group_ids
  idle_timeout       = var.idle_timeout
  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(var.tags, {
    "Name" = var.name
  })
}

# Create a Target Group for the ALB
resource "aws_lb_target_group" "this" {
  name_prefix = var.target_group_name_prefix
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  target_type = var.target_type
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = var.health_check_healthy_threshold
    unhealthy_threshold = var.health_check_unhealthy_threshold
    interval            = var.health_check_interval
    timeout             = var.health_check_timeout
    path                = var.health_check_path
    protocol            = var.target_group_protocol
  }

  tags = merge(var.tags, {
    "Name" = var.target_group_name_prefix
  })
}

# Create a Listener for the ALB that forwards traffic to the target group
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.listener_port
  protocol          = var.listener_protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
