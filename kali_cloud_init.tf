# cloud-init commands for configuring Kali instances

data "cloudinit_config" "kali_cloud_init_tasks" {
#   Must be updated to use for_each since we are using an array of names instead of numbers
#   count = lookup(var.operations_instance_counts, "kali", 0)

  gzip          = true
  base64_encode = true

  # Note: The filename parameters in each part below are only used to
  # name the mime-parts of the user-data.  They do not affect the
  # final name for the templates. For any x-shellscript parts, the
  # filenames will also be used as a filename in the scripts
  # directory.

  # Set the local hostname.
  #
  # We need to go ahead and set the local hostname to the correct
  # value that will eventually be obtained from DHCP, since we make
  # liberal use of the "{local_hostname}" placeholder in our AWS
  # CloudWatch Agent configuration.
  part {
    for_each = toset(var.kali_names)
    content = templatefile(
      "${path.module}/cloud-init/set-hostname.tpl.yml", {
        # Note that the hostname here is identical to what is set in
        # the corresponding DNS A record.
        fqdn     = "kali-${each.value}.${data.terraform_remote_state.cool_assessment_terraform.outputs.assessment_private_zone.name}"
        hostname = "kali-${each.value}"
    })
    content_type = "text/cloud-config"
    filename     = "set-hostname.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  # Create an fstab entry for the EFS share
  part {
    content = templatefile(
      "${path.module}/cloud-init/efs-mount.tpl.yml", {
        # Use the access point that corresponds with the EFS mount target used
        efs_ap_id = data.terraform_remote_state.cool_assessment_terraform.outputs.efs_access_points[data.terraform_remote_state.cool_assessment_terraform.outputs.private_subnet_cidr_blocks[0]].id
        # Just mount the EFS mount target in the first private subnet
        efs_id      = data.terraform_remote_state.cool_assessment_terraform.outputs.efs_mount_targets[data.terraform_remote_state.cool_assessment_terraform.outputs.private_subnet_cidr_blocks[0]].file_system_id
        group       = var.efs_mount_point_group
        mount_point = "/share"
        owner       = var.efs_mount_point_owner
    })
    content_type = "text/cloud-config"
    filename     = "efs_mount.yml"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

  # This shell script loops until the EFS share is mounted.  We do
  # make the instance depend on the EFS share in the Terraform code,
  # but it is still possible for an instance to boot up without
  # mounting the share.  See this issue comment for more details:
  # https://github.com/cisagov/cool-assessment-terraform/issues/85#issuecomment-754052796
  part {
    content = templatefile(
      "${path.module}/cloud-init/mount-efs-share.tpl.sh", {
        mount_point = "/share"
    })
    content_type = "text/x-shellscript"
    filename     = "mount-efs-share.sh"
    merge_type   = "list(append)+dict(recurse_array)+str()"
  }

}