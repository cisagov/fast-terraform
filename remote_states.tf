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