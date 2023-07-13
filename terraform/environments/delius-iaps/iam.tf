resource "aws_iam_role" "ci_data_refresher" {
  count              = local.is-production || local.is-preproduction ? 1 : 0
  name               = "ci-data-refresher"
  assume_role_policy = data.aws_iam_policy_document.ci_assume_role.json
  tags               = local.tags
}

data "aws_iam_policy_document" "ci_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = "token.actions.githubusercontent.com:aud"
    }
    condition {
      test     = "StringLike"
      values   = ["repo:ministryofjustice/modernisation-platform-configuration-management:*"]
      variable = "token.actions.githubusercontent.com:sub"
    }
  }
}

locals {
  iaps_rds_snapshot_arn_pattern_prod    = "arn:aws:rds:${data.aws_region.current.name}:${local.environment_management.account_ids["delius-iaps-production"]}:snapshot:*iaps-*"
  iaps_rds_snapshot_arn_pattern_preprod = "arn:aws:rds:${data.aws_region.current.name}:${local.environment_management.account_ids["delius-iaps-preproduction"]}:snapshot:*iaps-*"
}

data "aws_iam_policy_document" "snapshot_sharer" {
  statement {
    sid    = "CopyAndShareSnapshots"
    effect = "Allow"
    actions = [
      "rds:CopyDBSnapshot",
      "rds:DescribeDBSnapshots",
      "rds:ModifyDBSnapshotAttribute",
      "ssm:PutParameter"
    ]
    resources = [
      local.iaps_rds_snapshot_arn_pattern_preprod,
      local.iaps_rds_snapshot_arn_pattern_prod,
      aws_db_instance.iaps.arn
    ]
  }
  statement {
    sid    = "AllowKMSUsage"
    effect = "Allow"
    actions = [
      "kms:DescribeKey",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:CreateGrant"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "snapshot_sharer" {
  count       = local.is-production || local.is-preproduction ? 1 : 0
  name        = "snapshot_sharer"
  description = "Allows sharing of RDS snapshots"
  policy      = data.aws_iam_policy_document.snapshot_sharer.json
}

resource "aws_iam_role_policy_attachment" "ci_data_refresher" {
  count      = local.is-production || local.is-preproduction ? 1 : 0
  policy_arn = aws_iam_policy.snapshot_sharer[0].arn
  role       = aws_iam_role.ci_data_refresher[0].name
}
