# Find Kali AMI
data "aws_ami" "kali" {
  filter {
    name = "name"
    values = [
      "kali-hvm-*-x86_64-ebs"
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
  
  # Unsure if needed or possible to use with level of access and without incorporating all COOL variables from local.tf
  #owners      = [local.images_account_id]
  most_recent = true
}

# Create Kali instances, the number of instances is determined by the number of names present in the kali_names variable within variables.tf.
resource "aws_instance" "kali" {
  for_each = toset(var.kali_names)

  ami                         = data.aws_ami.kali.id
  associate_public_ip_address = false
  iam_instance_profile        = data.terraform_remote_state.cool_assessment_terraform.outputs.kali_instance_profile.name
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
  
  # Cloud-init response data. See kali_cloud_init.tf for each of the tasks being completed.
  user_data_base64 = data.cloudinit_config.kali_cloud_init_tasks[each.value].rendered

  # Security groups that all kali's will be a part of. All security groups prefixed with "data.terraform_remote_state." are managed by NOM.
  # All groups prefixed with "aws_security_group." and managed through this code base. 
  vpc_security_group_ids = [
    aws_security_group.kali_custom.id,
    data.terraform_rcccccbceglhgvnkneluerljcbbcuijremote_state.cool_assessment_terraform.outputs.cloudwatch_agent_endpoint_client_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.efs_client_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.guacamole_accessible_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.kali_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.s3_endpoint_client_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.scanner_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.ssm_agent_endpoint_client_security_group.id,
    data.terraform_remote_state.cool_assessment_terraform.outputs.sts_endpoint_client_security_group.id,
  ]
  tags = {
    Name = format("Kali-%s", each.value)
  }
  # volume_tags does not yet inherit the default tags from the
  # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # details.
  volume_tags = merge(data.aws_default_tags.assessment.tags, {
    Name = format("Kali-%s", each.value)
  })
}

# Route 53
# Private DNS A record for Kali instance
resource "aws_route53_record" "kali_A" {
  for_each = toset(var.kali_names)
  zone_id = data.terraform_remote_state.cool_assessment_terraform.outputs.assessment_private_zone.zone_id
  name    = "kali-${each.value}.${data.terraform_remote_state.cool_assessment_terraform.outputs.assessment_private_zone.name}"
  type    = "A"
  ttl     = var.dns_ttl
  records = [aws_instance.kali[each.value].private_ip]
}

# Elastic IPs
# The Elastic IP for each Kali instance
resource "aws_eip" "kali" {
  for_each = toset(var.kali_names)
  domain = "vpc"
  tags = {
    Name             = "${each.value} EIP"
    "Publish Egress" = "True"
  }
}

# The EIP association for the Kali
resource "aws_eip_association" "kali" {
  for_each = toset(var.kali_names)
  instance_id   = aws_instance.kali[each.value].id
  allocation_id = aws_eip.kali[each.value].id
}

# Security group for the Kali Linux instances
resource "aws_security_group" "kali_custom" {
  vpc_id = data.terraform_remote_state.cool_assessment_terraform.outputs.vpc.id

  tags = {
    Name = "Kali_Custom"
  }
}

# Security group rule to allow ingress of 22 from terraformer security group and rengine security group to kali_custom security group.
resource "aws_security_group_rule" "kali_ingress_from_terraformer" {
  security_group_id        = aws_security_group.kali_custom.id
  type                     = "ingress"
  protocol                 = "tcp"
  source_security_group_id = [
    data.terraform_remote_state.cool_assessment_terraform.outputs.terraformer_security_group.id,
    aws_security_group.rengine_custom.id,
  ]
  from_port                = 22
  to_port                  = 22
  description              = "Allow ingress of 22 from Terraformer Security Group"
}