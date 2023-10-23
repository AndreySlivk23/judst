module "iambackup" {
  source = "./modules/lambdapolicy"
    backup_policy_name = "laa-${local.application_name}-${local.environment}-policy"
    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}
module "lambda_backup" {
  source = "./modules/lambda"
  vpc_id = data.aws_vpc.shared.id
security_grp_name = "${local.application_name}-${local.environment}-lambdaSecurityGroup"
backup_policy_name = "${local.application_name}-lambda-instance-policy"
source_file   = local.dbsourcefiles
output_path   = local.zipfiles
filename      = local.zipfiles
function_name = local.functions
handler       = local.handlers
role = module.iambackup.backuprole
runtime = local.runtime
subnet_ids = data.aws_subnet.private_subnets_a.id


    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}


