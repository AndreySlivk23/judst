module "ip_addresses" {
  source = "../../modules/ip_addresses"
}

module "environment" {
  source = "../../modules/environment"

  providers = {
    aws.modernisation-platform = aws.modernisation-platform
    aws.core-network-services  = aws.core-network-services
    aws.core-vpc               = aws.core-vpc
  }
  environment_management = local.environment_management
  business_unit          = local.business_unit
  application_name       = local.application_name
  environment            = local.environment
  subnet_set             = local.subnet_set
  shared_s3_bucket       = lookup(local, "shared_s3_bucket", null) # This lives in one account and tf data s3 sources can't do filtering etc, the only way is to hardcode the bucket name. 
}

# #------------------------------------------------------------------------------
# # baseline module ec2 instance
# #------------------------------------------------------------------------------

module "baseline" {
  source = "../../modules/baseline"

  providers = {
    aws                       = aws
    aws.core-network-services = aws.core-network-services
    aws.core-vpc              = aws.core-vpc
  }

  security_groups       = local.baseline_security_groups
  acm_certificates      = module.baseline_presets.acm_certificates
  cloudwatch_log_groups = module.baseline_presets.cloudwatch_log_groups
  iam_policies          = module.baseline_presets.iam_policies
  iam_roles             = module.baseline_presets.iam_roles
  # iam_service_linked_roles = module.baseline_presets.iam_service_linked_roles
  key_pairs         = module.baseline_presets.key_pairs
  kms_grants        = module.baseline_presets.kms_grants
  route53_resolvers = module.baseline_presets.route53_resolvers
  #route53_zones
  s3_buckets        = merge(local.baseline_s3_buckets, lookup(local.environment_config, "baseline_s3_buckets", {}))
  # rds_instances
  #sns_topics

  #bastion_linux = lookup(local.environment_config, "baseline_bastion_linux", null)

  environment = module.environment

  ec2_instances          = lookup(local.environment_config, "baseline_ec2_instances", {})
  ec2_autoscaling_groups = lookup(local.environment_config, "baseline_ec2_autoscaling_groups", {})
  lbs                    = lookup(local.environment_config, "baseline_lbs", {})
}

module "baseline_presets" {
  source = "../../modules/baseline_presets"

  environment  = module.environment
  ip_addresses = module.ip_addresses

  options = {
    cloudwatch_log_groups                        = null
    enable_application_environment_wildcard_cert = true
    enable_business_unit_kms_cmks                = true
    enable_image_builder                         = true
    enable_ec2_cloud_watch_agent                 = true
    enable_ec2_self_provision                    = true
    enable_shared_s3                             = true
    s3_iam_policies                              = ["EC2S3BucketWriteAndDeleteAccessPolicy"]

    # comment this in if you need to resolve FixNGo hostnames
    # route53_resolver_rules = {
    #   outbound-data-and-private-subnets = ["azure-fixngo-domain"]
    # }
  }
}

# --- AWS Resource Explorer ---
resource "aws_resourceexplorer2_index" "this" {
  type = "LOCAL"
}

resource "aws_resourceexplorer2_view" "all_resources" {
  name         = "all-resources"
  default_view = true
  depends_on   = [aws_resourceexplorer2_index.this]
}



# count             = local.environment == "test" ? 1 : 0


# count             = local.environment == "development" ? 1 : 0

# arn:aws:s3:::devtest-oasys20230403154135527100000001/*