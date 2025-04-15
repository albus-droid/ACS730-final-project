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
