provider "aws" {
  region = var.region
}

# -----------------------------------------------------
# VPC Module
# -----------------------------------------------------
module "vpc" {
  source   = "../modules/vpc"
  vpc_cidr = "10.1.0.0/16"
  vpc_name = "Staging-VPC"
  # Four public subnets and two private subnets
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24"]
  private_subnet_cidrs = ["10.0.101.0/24", "10.0.102.0/24"]
  # Supply at least as many AZs as public subnets (adjust if needed)
  azs         = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d"]
  environment = var.environment
  tags = {
    Project = "Final-Project"
    Owner   = "Albin"
  }
}

# -----------------------------------------------------
# Security Groups
# -----------------------------------------------------

# ALB Security Group: allow inbound HTTP from anywhere.
resource "aws_security_group" "alb_sg" {
  name        = "${var.environment}-alb-sg"
  description = "ALB security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
  }
}

# Webserver Security Group: allow HTTP (from ALB) and SSH (for management).
resource "aws_security_group" "web_sg" {
  name        = "${var.environment}-web-sg"
  description = "Webserver security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  ingress {
    description = "Allow SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Adjust to restrict SSH access in production
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
  }
}

# Bastion Host Security Group: restrict SSH ingress to your IP.
resource "aws_security_group" "bastion_sg" {
  name        = "${var.environment}-bastion-sg"
  description = "Bastion host security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow SSH access from your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Replace YOUR_PUBLIC_IP with your actual public IP
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
  }
}

# -----------------------------------------------------
# ASG for Webservers (Webserver 1 & 3 with ALB)
# -----------------------------------------------------

# Create a Launch Template for the ASG-managed webservers.
resource "aws_launch_template" "webserver_lt" {
  name_prefix            = "${var.environment}-webserver-"
  image_id               = "ami-00a929b66ed6e0de6" # Update with a valid AMI ID
  instance_type          = "t2.micro"
  key_name               = "vockey" # Update with your EC2 key pair
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from ASG Webserver" > /var/www/html/index.html
EOF
  )
}

# Create the Auto Scaling Group for the ASG-managed webservers.
resource "aws_autoscaling_group" "web_asg" {
  name             = "${var.environment}-web-asg"
  max_size         = 2
  min_size         = 2
  desired_capacity = 2

  launch_template {
    id      = aws_launch_template.webserver_lt.id
    version = "$Latest"
  }

  # Place ASG instances in the first and third public subnets (Webserver 1 & 3)
  vpc_zone_identifier = [
    module.vpc.public_subnet_ids[0],
    module.vpc.public_subnet_ids[2]
  ]

  target_group_arns         = [module.alb.target_group_arn] # Attach to ALB target group
  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "ASG-Webserver"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

# -----------------------------------------------------
# Additional Standalone EC2 Instances (Using the EC2 Module)
# -----------------------------------------------------
module "ec2_extra" {
  source      = "../modules/ec2"
  environment = var.environment
  tags = {
    Project = "Final-Project"
    Owner   = "Albin"
  }
  instances = [
    # Bastion Host in Public Subnet 2 (Webserver 2 - not a webserver)
    {
      name                        = "BastionHost"
      instance_type               = "t2.micro"
      ami                         = "ami-00a929b66ed6e0de6" # Update with the proper AMI ID
      subnet_id                   = module.vpc.public_subnet_ids[1]
      key_name                    = "vockey"
      security_group_ids          = [aws_security_group.bastion_sg.id]
      associate_public_ip_address = true
      user_data                   = ""
    },
    # Additional Public Webserver in Public Subnet 4 (Webserver 4)
    {
      name                        = "Webserver_Public"
      instance_type               = "t2.micro"
      ami                         = "ami-00a929b66ed6e0de6"
      subnet_id                   = module.vpc.public_subnet_ids[3]
      key_name                    = "vockey"
      security_group_ids          = [aws_security_group.web_sg.id]
      associate_public_ip_address = true
      user_data                   = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from Public Webserver" > /var/www/html/index.html
EOF
    },
    # Private Webserver in Private Subnet 1 (Webserver 5 using NAT)
    {
      name                        = "Webserver_Private_1"
      instance_type               = "t2.micro"
      ami                         = "ami-00a929b66ed6e0de6"
      subnet_id                   = module.vpc.private_subnet_ids[0]
      key_name                    = "vockey"
      security_group_ids          = [aws_security_group.web_sg.id]
      associate_public_ip_address = false
      user_data                   = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from Private Webserver 1" > /var/www/html/index.html
EOF
    },
    # Private Webserver in Private Subnet 2 (Webserver 6)
    {
      name                        = "Webserver_Private_2"
      instance_type               = "t2.micro"
      ami                         = "ami-00a929b66ed6e0de6"
      subnet_id                   = module.vpc.private_subnet_ids[1]
      key_name                    = "vockey"
      security_group_ids          = [aws_security_group.web_sg.id]
      associate_public_ip_address = false
      user_data                   = <<-EOF
#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "Hello from Private Webserver 2" > /var/www/html/index.html
EOF
    }
  ]
}

# -----------------------------------------------------
# ALB Module
# -----------------------------------------------------
module "alb" {
  source = "../modules/alb"

  name                       = "ALB"
  subnet_ids                 = module.vpc.public_subnet_ids
  security_group_ids         = [aws_security_group.alb_sg.id]
  idle_timeout               = 60
  enable_deletion_protection = false
  tags = {
    Project = "Final-Project"
    Owner   = "Albin"
  }

  vpc_id                           = module.vpc.vpc_id
  target_group_name_prefix         = "Target"
  target_group_port                = 80
  target_group_protocol            = "HTTP"
  target_type                      = "instance"
  health_check_healthy_threshold   = 3
  health_check_unhealthy_threshold = 3
  health_check_interval            = 30
  health_check_timeout             = 5
  health_check_path                = "/"

  listener_port     = 80
  listener_protocol = "HTTP"
}
