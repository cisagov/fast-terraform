# The Debian AMI, which we use for our "Debian desktop" instances
data "aws_ami" "debiandesktop" {

  filter {
    name = "name"
    values = [
      "debian-hvm-*-x86_64-ebs"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  owners      = [local.images_account_id]
  most_recent = true
}

# The "Debian desktop" EC2 instances
resource "aws_instance" "rengine" {
  ami                         = data.aws_ami.debiandesktop.id
  associate_public_ip_address = false
  iam_instance_profile        = data.terraform_remote_state.cool_assessment_terraform.outputs.debian_desktop_instance_profile.name
  instance_type               = "t3.xlarge"
  subnet_id                   = data.terraform_remote_state.cool_assessment_terraform.outputs.operations_subnet.id
  # AWS Instance Meta-Data Service (IMDS) options
  metadata_options {
    # Enable IMDS (this is the default value)
    http_endpoint = "enabled"
    # Restrict put responses from IMDS to a single hop (this is the
    # default value).  This effectively disallows the retrieval of an
    # IMDSv2 token via this machine from anywhere else.
    http_put_response_hop_limit = 1
    # Require IMDS tokens AKA require the use of IMDSv2
    http_tokens = "required"
  }
  root_block_device {
    volume_size = 128
    volume_type = "gp3"
  }
  #user_data_base64 = data.cloudinit_config.debiandesktop_cloud_init_tasks[count.index].rendered

  vpc_security_group_ids = [
    #TODO: Determine correct security groups for debiandesktop
    aws_security_group.rengine_custom.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.cloudwatch_agent_endpoint_client_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.efs_client_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.guacamole_accessible_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.ssm_agent_endpoint_client_security_group.id,

  ]
  tags = {
    Name = "ReNgine"
  }
  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(data.aws_default_tags.assessment.tags, {
    Name = "ReNgine"
  })
}

# Route 53
# Private DNS A record for ReNgine instance
resource "aws_route53_record" "rengine_A" {
  zone_id = data.terraform_remote_state.cool_assessment_terraform.outputs.assessment_private_zone.zone_id
  name    = "rengine.${data.terraform_remote_state.cool_assessment_terraform.outputs.assessment_private_zone.name}"
  type    = "A"
  ttl     = var.dns_ttl
  records = [aws_instance.rengine.private_ip]
}

# Elastic IPs
# The Elastic IP for each Kali instance
resource "aws_eip" "rengine" {
  domain = "vpc"
  tags = {
    Name             = "ReNgine EIP"
    "Publish Egress" = "True"
  }
}

# The EIP association for the Teamserver
resource "aws_eip_association" "rengine" {
  instance_id   = aws_instance.rengine.id
  allocation_id = aws_eip.rengine.id
}

# Security group for the ReNgine instances
resource "aws_security_group" "rengine_custom" {
  vpc_id = data.terraform_remote_state.cool_assessment_terraform.outputs.vpc.id

  tags = {
    Name = "ReNgine_Custom"
  }
}

# Security group rule to allow ingress of 443,3000,6379 from Kali_Custom Security Group and Windows Security Group.
resource "aws_security_group_rule" "rengine_ingress_to_allowed_ports" {
  foreach = toset(["22","443","3000","6379"])
  security_group_id        = aws_security_group.rengine_custom.id
  type                     = "ingress"
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.kali_custom.id
  from_port                = each.value
  to_port                  = each.value
  description              = "Allow ingress from Kali_Custom Security Group to ReNgine Security Group"
}

# Security group rule to allow ingress of 22 from Kali_Custom Security Group and Windows Security Group.
resource "aws_security_group_rule" "rengine_ingress_to_allowed_ports" {
  foreach = toset(["22","443","3000","6379"])
  security_group_id        = aws_security_group.rengine_custom.id
  type                     = "ingress"
  protocol                 = "tcp"
  source_security_group_id = data.terraform_remote_state.cool_assessment_terraform.outputs.terraformer_security_group.id
  from_port                = each.value
  to_port                  = each.value
  description              = "Allow ingress of 22 from Terraformer Security Group to ReNgine Security Group"
}

# Security group rule to allow egress of 22 to any proxy boxes.
resource "aws_security_group_rule" "rengine_egress_to_kali" {
  security_group_id        = aws_security_group.rengine_custom.id
  type                     = "egress"
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
  from_port                = 22
  to_port                  = 22
  description              = "Allow egress of 22 to Any"
}

# For: Assessment team web access, package downloads and updates
resource "aws_security_group_rule" "rengine_egress_to_anywhere_via_http_and_https" {
  for_each = toset(["80", "443"])

  security_group_id = aws_security_group.rengine_custom.id
  type              = "egress"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = each.key
  to_port           = each.key
}
