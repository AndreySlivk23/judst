module "lambda_backup" {
  source = "./module/lambda"

backup_policy_name = "${local.application_name}-lambda-instance-policy"
source_file   = ["dbsnapshot.js","deletesnapshots.py"]
output_path   = ["snapshotDBFunction.zip","deletesnapshotFunction.zip"]
filename      = ["snapshotDBFunction", "deletesnapshotFunction"]
function_name = ["snapshotDBFunction","deletesnapshotFunction"]
handler       = ["snapshot/dbsnapshot.handler","deletesnapshots.lambda_handler"]

    tags = merge(
    local.tags,
    { Name = "laa-${local.application_name}-${local.environment}-mp" }
  )
}
