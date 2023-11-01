locals {
  domain_refresh_establishment_establishment    = "${local.project}-temp-domain-refresh-establishment-establishment-${local.env}"
  domain_refresh_establishment_living_unit      = "${local.project}-temp-domain-refresh-establishment-living_unit-${local.env}"
  domain_refresh_movements_movements            = "${local.project}-temp-domain-refresh-movements-movements-${local.env}"
  domain_refresh_prisoner_prisoner              = "${local.project}-temp-domain-refresh-prisoner-prisoner-${local.env}"
}

# Glue Job, Domain Refresh establishment/establishment
module "glue_temp_domain_refresh_job_establishment_establishment" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.domain_refresh_establishment_establishment
  short_name                    = local.domain_refresh_establishment_establishment
  command_type                  = "glueetl"
  description                   = "Monitors the reporting hub for table changes and applies them to domains"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.domain_refresh_establishment_establishment}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.domain_refresh_establishment_establishment}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.domain_refresh_establishment_establishment}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  additional_policies          = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  # timeout                       = 1440
  execution_class             = "FLEX"
  worker_type                 = local.refresh_job_worker_type
  number_of_workers           = local.refresh_job_num_workers
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = 1

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.domain_refresh_establishment_establishment}"
      Resource_Type = "Glue Job"
      Jira          = "DPR2-193"
    }
  )

  arguments = {
    "--extra-jars"                   = local.glue_jobs_latest_jar_location
    "--class"                        = "uk.gov.justice.digital.job.DomainRefreshJob"
    "--datalake-formats"             = "delta"
    "--dpr.aws.dynamodb.endpointUrl" = "https://dynamodb.${local.account_region}.amazonaws.com"
    "--dpr.aws.kinesis.endpointUrl"  = "https://kinesis.${local.account_region}.amazonaws.com"
    "--dpr.aws.region"               = local.account_region
    "--dpr.curated.s3.path"          = "s3://${module.s3_curated_bucket.bucket_id}"
    "--dpr.domain.registry"          = "${local.project}-domain-registry-${local.environment}"
    "--dpr.domain.target.path"       = "s3://${module.s3_domain_bucket.bucket_id}"
    "--dpr.domain.catalog.db"        = module.glue_data_domain_database.db_name
    "--dpr.log.level"                = local.refresh_job_log_level
    "--dpr.domain.name"              = "establishment"
    "--dpr.domain.table.name"        = "establishment"
    "--dpr.domain.operation"         = "sync"
  }
}


# Glue Job, Domain Refresh establishment/living_unit
module "glue_temp_domain_refresh_job_establishment_living_unit" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.domain_refresh_establishment_living_unit
  short_name                    = local.domain_refresh_establishment_living_unit
  command_type                  = "glueetl"
  description                   = "Monitors the reporting hub for table changes and applies them to domains"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.domain_refresh_establishment_living_unit}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.domain_refresh_establishment_living_unit}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.domain_refresh_establishment_living_unit}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  additional_policies          = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  # timeout                       = 1440
  execution_class             = "FLEX"
  worker_type                 = local.refresh_job_worker_type
  number_of_workers           = local.refresh_job_num_workers
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = 1

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.domain_refresh_establishment_living_unit}"
      Resource_Type = "Glue Job"
      Jira          = "DPR2-193"
    }
  )

  arguments = {
    "--extra-jars"                   = local.glue_jobs_latest_jar_location
    "--class"                        = "uk.gov.justice.digital.job.DomainRefreshJob"
    "--datalake-formats"             = "delta"
    "--dpr.aws.dynamodb.endpointUrl" = "https://dynamodb.${local.account_region}.amazonaws.com"
    "--dpr.aws.kinesis.endpointUrl"  = "https://kinesis.${local.account_region}.amazonaws.com"
    "--dpr.aws.region"               = local.account_region
    "--dpr.curated.s3.path"          = "s3://${module.s3_curated_bucket.bucket_id}"
    "--dpr.domain.registry"          = "${local.project}-domain-registry-${local.environment}"
    "--dpr.domain.target.path"       = "s3://${module.s3_domain_bucket.bucket_id}"
    "--dpr.domain.catalog.db"        = module.glue_data_domain_database.db_name
    "--dpr.log.level"                = local.refresh_job_log_level
    "--dpr.domain.name"              = "establishment"
    "--dpr.domain.table.name"        = "living_unit"
    "--dpr.domain.operation"         = "sync"
  }
}



# Glue Job, Domain Refresh movements/movements
module "glue_temp_domain_refresh_job_movements_movements" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.domain_refresh_movements_movements
  short_name                    = local.domain_refresh_movements_movements
  command_type                  = "glueetl"
  description                   = "Monitors the reporting hub for table changes and applies them to domains"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.domain_refresh_movements_movements}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.domain_refresh_movements_movements}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.domain_refresh_movements_movements}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  additional_policies          = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  # timeout                       = 1440
  execution_class             = "FLEX"
  worker_type                 = local.refresh_job_worker_type
  number_of_workers           = local.refresh_job_num_workers
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = 1

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.domain_refresh_movements_movements}"
      Resource_Type = "Glue Job"
      Jira          = "DPR2-193"
    }
  )

  arguments = {
    "--extra-jars"                   = local.glue_jobs_latest_jar_location
    "--class"                        = "uk.gov.justice.digital.job.DomainRefreshJob"
    "--datalake-formats"             = "delta"
    "--dpr.aws.dynamodb.endpointUrl" = "https://dynamodb.${local.account_region}.amazonaws.com"
    "--dpr.aws.kinesis.endpointUrl"  = "https://kinesis.${local.account_region}.amazonaws.com"
    "--dpr.aws.region"               = local.account_region
    "--dpr.curated.s3.path"          = "s3://${module.s3_curated_bucket.bucket_id}"
    "--dpr.domain.registry"          = "${local.project}-domain-registry-${local.environment}"
    "--dpr.domain.target.path"       = "s3://${module.s3_domain_bucket.bucket_id}"
    "--dpr.domain.catalog.db"        = module.glue_data_domain_database.db_name
    "--dpr.log.level"                = local.refresh_job_log_level
    "--dpr.domain.name"              = "movements"
    "--dpr.domain.table.name"        = "movements"
    "--dpr.domain.operation"         = "sync"
  }
}


# Glue Job, Domain Refresh prisoner/prisoner
module "glue_temp_domain_refresh_job_prisoner_prisoner" {
  source                        = "./modules/glue_job"
  create_job                    = local.create_job
  name                          = local.domain_refresh_prisoner_prisoner
  short_name                    = local.domain_refresh_prisoner_prisoner
  command_type                  = "glueetl"
  description                   = "Monitors the reporting hub for table changes and applies them to domains"
  create_security_configuration = local.create_sec_conf
  job_language                  = "scala"
  temp_dir                      = "s3://${module.s3_glue_job_bucket.bucket_id}/tmp/${local.domain_refresh_prisoner_prisoner}/"
  checkpoint_dir                = "s3://${module.s3_glue_job_bucket.bucket_id}/checkpoint/${local.domain_refresh_prisoner_prisoner}/"
  spark_event_logs              = "s3://${module.s3_glue_job_bucket.bucket_id}/spark-logs/${local.domain_refresh_prisoner_prisoner}/"
  # Placeholder Script Location
  script_location              = local.glue_placeholder_script_location
  enable_continuous_log_filter = false
  project_id                   = local.project
  aws_kms_key                  = local.s3_kms_arn
  additional_policies          = module.kinesis_stream_ingestor.kinesis_stream_iam_policy_admin_arn
  # timeout                       = 1440
  execution_class             = "FLEX"
  worker_type                 = local.refresh_job_worker_type
  number_of_workers           = local.refresh_job_num_workers
  max_concurrent              = 64
  region                      = local.account_region
  account                     = local.account_id
  log_group_retention_in_days = 1

  tags = merge(
    local.all_tags,
    {
      Name          = "${local.domain_refresh_prisoner_prisoner}"
      Resource_Type = "Glue Job"
      Jira          = "DPR2-193"
    }
  )

  arguments = {
    "--extra-jars"                   = local.glue_jobs_latest_jar_location
    "--class"                        = "uk.gov.justice.digital.job.DomainRefreshJob"
    "--datalake-formats"             = "delta"
    "--dpr.aws.dynamodb.endpointUrl" = "https://dynamodb.${local.account_region}.amazonaws.com"
    "--dpr.aws.kinesis.endpointUrl"  = "https://kinesis.${local.account_region}.amazonaws.com"
    "--dpr.aws.region"               = local.account_region
    "--dpr.curated.s3.path"          = "s3://${module.s3_curated_bucket.bucket_id}"
    "--dpr.domain.registry"          = "${local.project}-domain-registry-${local.environment}"
    "--dpr.domain.target.path"       = "s3://${module.s3_domain_bucket.bucket_id}"
    "--dpr.domain.catalog.db"        = module.glue_data_domain_database.db_name
    "--dpr.log.level"                = local.refresh_job_log_level
    "--dpr.domain.name"              = "prisoner"
    "--dpr.domain.table.name"        = "prisoner"
    "--dpr.domain.operation"         = "sync"
  }
}

# =======================================
# SCHEDULES
# =======================================

# Establishment Establishment Schedule
resource "aws_glue_trigger" "temp_domain_refresh_establishment_establishment" {
  name     = "${local.domain_refresh_establishment_establishment}-trigger"
  schedule = "cron(*/15 06-20 * * MON-FRI)"
  type     = "SCHEDULED"

  actions {
    job_name = module.glue_temp_domain_refresh_job_establishment_establishment
  }
}


# Establishment Living Unit Schedule
resource "aws_glue_trigger" "temp_domain_refresh_establishment_living_unit" {
  name     = "${local.domain_refresh_establishment_living_unit}-trigger"
  schedule = "cron(*/15 06-20 * * MON-FRI)"
  type     = "SCHEDULED"

  actions {
    job_name = module.glue_temp_domain_refresh_job_establishment_living_unit
  }
}


# Movements Movements Schedule
resource "aws_glue_trigger" "temp_domain_refresh_movements_movements" {
  name     = "${local.domain_refresh_movements_movements}-trigger"
  schedule = "cron(*/15 06-20 * * MON-FRI)"
  type     = "SCHEDULED"

  actions {
    job_name = module.glue_temp_domain_refresh_job_movements_movements
  }
}



# Prisoner Prisoner Schedule
resource "aws_glue_trigger" "temp_domain_refresh_prisoner_prisoner" {
  name     = "${local.domain_refresh_prisoner_prisoner}-trigger"
  schedule = "cron(*/15 06-20 * * MON-FRI)"
  type     = "SCHEDULED"

  actions {
    job_name = module.glue_temp_domain_refresh_job_prisoner_prisoner
  }
}