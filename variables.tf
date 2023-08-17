# All configurable variables available

# CURRENTLY USELESS
# variable "kali_ingress" {
#     type = list
#     description = "All available ingress ports to Kali VMs"
#     default = [8080,8000]
# }

# variable "kali_egress" {
#     type = list
#     description = "All available egress ports from Kali VMs"
#     default = [8080,8000]
# }

variable "kali_names" {
    type = list
    description = "List of names to be used in creation of Kalis. E.g Kali-Andrew"
    default = ["Operator1", "Operator2", "Operator3"]
}


# ------------------------------------------------------------------------------
# DEFAULT COOL PARAMETERS
#
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------

variable "aws_region" {
  type        = string
  description = "The AWS region where the non-global resources for this assessment are to be provisioned (e.g. \"us-east-1\")."
  default     = "us-east-1"
}

variable "dns_ttl" {
  type        = number
  description = "The TTL value to use for Route53 DNS records (e.g. 86400).  A smaller value may be useful when the DNS records are changing often, for example when testing."
  default     = 60
}

variable "efs_mount_point_group" {
  type        = string
  description = "The name of the group that should own the EFS share mount point on the deployed instance."
  default     = "efs_users"
}

variable "efs_mount_point_owner" {
  type        = string
  description = "The name of the user that should own the EFS share mount point on the deployed instance."
  default     = "vnc"
}

variable "email_sending_domain" {
  type        = string
  description = "The domain to send emails from within the assessment environment (e.g. \"example.com\")."
  default     = "example.com"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all AWS resources created."
  default     = {}
}
