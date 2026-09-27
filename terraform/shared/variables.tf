# TFC Configuration
# https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/aws-configuration
variable "tfc_aws_dynamic_credentials" {
  description = "Object containing AWS dynamic credentials configuration"
  type = object({
    default = object({
      shared_config_file = string
    })
    aliases = map(object({
      shared_config_file = string
    }))
  })
  default = null
}

# AWS Configuration
variable "aws_region_name" {
  type        = string
  description = "AWS region name"
  default     = "ap-northeast-1"
}

# System Environment Configuration
variable "env_name" {
  type        = string
  description = "Environment name"
}

variable "system_name" {
  type        = string
  description = "System name"
  default     = "costkeeper"
}

# Lambda Configuration
variable "discord_webhook_url" {
  type        = string
  description = "Discord webhook URL to notify AWS cost"
  sensitive   = true
}

variable "schedule_expression" {
  type        = string
  description = "Schedule expression of EventBridge Scheduler (UTC)"
  default     = "cron(5 0 * * ? *)"
}

variable "log_retention_in_days" {
  type        = number
  description = "Retention in days of Lambda function log group"
  default     = 30
}
