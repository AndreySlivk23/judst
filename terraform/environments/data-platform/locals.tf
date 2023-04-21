#### This file can be used to store locals specific to the member account ####
locals {

  ##
  # Variables code_extractor lambda
  ##
  function_name               = "code_extractor"
  function_handler            = "main.handler"
  function_runtime            = "python3.9"
  function_timeout_in_seconds = 15

  function_source_dir = "${path.module}/src/${local.function_name}"

  ##
  # Variables for glue job
  ##
  glue_default_arguments = {
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-glue-datacatalog"          = "true"
    "--enable-job-insights"              = "true"
    "--enable-continuous-log-filter"     = "true"
  }

  name                             = "data-platform-product"
  glue_version                     = "4.0"
  max_retries                      = 0
  worker_type                      = "G.1X"
  number_of_workers                = 2
  timeout                          = 120 # minutes
  execution_class                  = "STANDARD"
  max_concurrent                   = 5
  glue_log_group_retention_in_days = 7
}
