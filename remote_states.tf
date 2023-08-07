data "terraform_remote_state" "cool_assessment_terraform" {
  backend = "s3"
  config = {
    encrypt = true
    bucket  = "cisa-cool-terraform-state"
    profile = "read_cool_assessment_terraform_state"
    region  = "us-east-1"
    key     = "cool-assessment-terraform/terraform.tfstate"
  }
  workspace = local.assessment_workspace_name
}

# ----------------------------------------------------------------------------------------------------------------
# TESTING: These variables should not be needed as they are included in the COOL section of the default locals.tf
# ----------------------------------------------------------------------------------------------------------------

# data "aws_caller_identity" "assessment" {
# }

# data "aws_organizations_organization" "cool" {
# 	provider=aws.read-organization-information
# }

# data "aws_default_tags" "assessment" {
# }

# # ------------------------------------------------------------------------------
# # Retrieve the effective Account ID, User ID, and ARN in which Terraform is
# # authorized.  This is used to calculate the session names for assumed roles.
# # ------------------------------------------------------------------------------
# data "aws_caller_identity" "current" {}

# locals {
# 	assessment_account_id = data.aws_caller_identity.assessment.account_id
	
# 	assessment_account_name = [
#     		for account in data.aws_organizations_organization.cool.accounts :
#     		account.name
#     		if account.id == local.assessment_account_id
#  	][0]
 	
#  	assessment_account_type = length(regexall("\\(([^()]*)\\)", local.assessment_account_name)) == 1 ? regex("\\(([^()]*)\\)", local.assessment_account_name)[0] : "Unknown"
 	
#  	assessment_workspace_name = replace(replace(lower(local.assessment_account_name), "/[()]/", ""), " ", "-")
 	
#  	images_account_id = [
#     		for account in data.aws_organizations_organization.cool.accounts :
#     		account.id
#     		if account.name == "Images (${local.assessment_account_type})"
#   	][0]
  	
#   	# Extract the user name of the current caller for use
#   # as assume role session names.
#   caller_user_name = split("/", data.aws_caller_identity.current.arn)[1]
# }
