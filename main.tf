# Utilize EC2 instance metadata credentials
# Provider documentation using metadata creds: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#shared-configuration-and-credentials-files
# Cred file format documentation: https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html#cli-configure-files-format
provider "aws" {
  shared_credentials_files = ["$HOME/.aws/credentials"]
  profile                  = "default"
}

# Kali Resource


# Create a kali instances, the number of instances is determined by the number of names provided in the kali_names variable.
#    
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

# Create Kali instances
resource "aws_instance" "kali" {

  # # These instances require the EFS mount target to be present in
  # # order to mount the EFS volume at boot time.
  # depends_on = [
  #   aws_efs_mount_target.target,
  #   aws_security_group_rule.allow_nfs_inbound,
  #   aws_security_group_rule.allow_nfs_outbound,
  # ]

  ami                         = data.aws_ami.kali.id
  associate_public_ip_address = true
  # iam_instance_profile        = aws_iam_instance_profile.kali.name
  instance_type               = "t3.xlarge"
  # subnet_id                   = aws_subnet.operations.id
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
  # user_data_base64 = data.cloudinit_config.kali_cloud_init_tasks[count.index].rendered
  # vpc_security_group_ids = [
  #   aws_security_group.cloudwatch_agent_endpoint_client.id,
  #   aws_security_group.efs_client.id,
  #   aws_security_group.guacamole_accessible.id,
  #   aws_security_group.kali.id,
  #   aws_security_group.s3_endpoint_client.id,
  #   aws_security_group.scanner.id,
  #   aws_security_group.ssm_agent_endpoint_client.id,
  #   aws_security_group.sts_endpoint_client.id,
  # ]
  # tags = {
  #   Name = format("Kali%d", count.index)
  # }
  # # volume_tags does not yet inherit the default tags from the
  # # provider.  See hashicorp/terraform-provider-aws#19188 for more
  # # details.
  # volume_tags = merge(data.aws_default_tags.assessment.tags, {
  #   Name = format("Kali%d", count.index)
  # })
}
  # Default instance type (option to modify some?)
  # Increase disk size

# Security Group
# Add to existing security groups

# Subnets

# Elastic IPs

