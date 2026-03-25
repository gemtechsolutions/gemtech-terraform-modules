provider "aws" {
  region = "us-east-1"
}

locals {
  instance_name      = "example-relay-node"
  key_name           = "example-key"
  security_group_ids = ["sg-1234567890abcdef0"]
  subnet_id          = "subnet-1234567890abcdef0"
}

module "ec2" {
  source = "../"

  instance_name               = local.instance_name
  ami_id                      = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  key_name                    = local.key_name
  security_group_ids          = local.security_group_ids
  subnet_id                   = local.subnet_id
  associate_public_ip_address = true

  user_data = <<-EOT
    #!/bin/bash
    echo "relay node ready" > /var/tmp/relay.txt
  EOT
}
