# FAST-Terraform

# Usage

1. Modify `variables.tf` as necessary to fit your needs. (See the [Variables](#variables) section below for details)

2. Install necessary providers and configure remote state for use. Aka install dependencies 
        
    `terraform init`

3. Create a plan for creation of all resources. (Optional)

    `terraform plan`
4. Create all resources. Terraform will create a plan for all resource creation. It is HIGHLY recommended that you review this plan before deploying.

    `terraform apply`
5. Once all your resources have been used and your environment is ready to be destroyed.

    `terraform destroy`

# Variables

| Variable   | Description                                                                                                     |
|------------|-----------------------------------------------------------------------------------------------------------------|
| kali_names | Names to be used for each kali instance. The number of names identifies how many kali machines will be created. |

# Background Info
- Ingests remote state files from current COOL deployment.
- Remote state outputs can be used to as inputs to this code base.
