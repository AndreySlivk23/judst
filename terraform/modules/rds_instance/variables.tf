variable "region" {
  type        = string
  description = "Destination AWS Region for the infrastructure"
  default     = "eu-west-2"
}

variable "tags" {
  type        = map(any)
  description = "Default tags to be applied to resources"
}

variable "instance" {
  description = "RDS instance settings, see db_instance documentation"
  type = object({
    allocated_storage     = number
    name                  = string
    engine                = string
    engine_version        = string
    instance_class        = string
    username              = string
    password              = string
    parameter_group_name  = string
    skip_final_snapshot   = bool
    max_allocated_storage = number
  })
}

variable "db_instance_automated_backups_replication" {
  type    = number
  default = 14
}

variable "aws_db_option_group" {
  description = "RDS option group settings"
  type = object({
    name                 = string
    description          = string
    engine_name          = string
    major_engine_version = string
    options = list(object({
      name = string
      settings = list(object({
        name  = string
        value = string
      }))
    }))
  })
}

variable "aws_db_parameter_group" {
  description = "RDS parameter group settings"
  type = object({
    name                 = string
    description          = string
    engine_name          = string
    major_engine_version = string
    options = list(object({
      name = string
      settings = list(object({
        name  = string
        value = string
      }))
    }))
  })
}

variable "db_proxy" {
  description = "RDS proxy settings"
  type = object({
    name                   = string
    debug_logging          = bool
    engine_family          = string
    idle_client_timeout    = number
    require_tls            = bool
    role_arn               = string
    vpc_security_group_ids = list(string)
    vpc_subnet_ids         = list(string)

    auth = object({
      auth_scheme = string
      description = string
      iam_auth    = string
      secret_arn  = string
    })
  })
}

variable "db_proxy_default_target_group" {
  description = "RDS proxy default target group settings"
  type = object({
    db_proxy_name = string
    connection_pool_config = object({
      connection_borrow_timeout    = number
      init_query                   = string
      max_connections_percent      = number
      max_idle_connections_percent = number
      session_pinning_filters      = list(string)
    })
  })
}