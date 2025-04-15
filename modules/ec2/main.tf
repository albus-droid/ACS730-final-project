resource "aws_instance" "this" {
  for_each = { for inst in var.instances : inst.name => inst }

  ami                         = each.value.ami
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  key_name                    = each.value.key_name
  vpc_security_group_ids      = each.value.security_group_ids
  associate_public_ip_address = lookup(each.value, "associate_public_ip_address", false)
  user_data                   = each.value.user_data

  tags = merge(
    var.tags,
    {
      "Name"        = each.value.name,
      "Environment" = var.environment
    }
  )
}

resource "aws_lb_target_group_attachment" "ec2_extra_attachments" {
  for_each = module.ec2_extra.instance_ids

  target_group_arn = module.alb.target_group_arn
  target_id        = each.value   # Instance ID
  port             = 80           # Replace with your target port, if different
}
