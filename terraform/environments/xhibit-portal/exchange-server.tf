resource "aws_eip" "exchange" {
  instance = aws_instance.exchange-server.id
  vpc      = true
}

resource "aws_instance" "exchange-server" {

  depends_on                  = [aws_security_group.exchange_server]
  instance_type               = "t2.medium"
  ami                         = local.application_data.accounts[local.environment].infra6-ami
  vpc_security_group_ids      = [aws_security_group.exchange_server.id]
  monitoring                  = true
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.public_az_a.id
  key_name                    = aws_key_pair.george.key_name

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
    tags = {
      Name = "root-block-device-exchange-server-${local.application_name}"
    }
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      associate_public_ip_address,
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      #root_block_device,
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
    prevent_destroy = true
  }

  tags = merge(
    local.tags,
    {
      Name = "exchange-${local.application_name}"
    }
  )
}


