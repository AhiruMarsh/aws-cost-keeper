provider "aws" {
  region              = var.aws_region_name
  shared_config_files = try([var.tfc_aws_dynamic_credentials.default.shared_config_file], null)

  default_tags {
    tags = {
      Project   = "${var.system_name}-${var.env_name}"
      ManagedBy = "Terraform"
      GitRepos  = "https://github.com/AhiruMarsh/aws-cost-keeper"
    }
  }
}