#------------------------------------------------------------------------------
# IAM for S3 data movement operations to and from the Analytical Platform (AP)
# 
#------------------------------------------------------------------------------


# S3 bucket access policy for AP landing bucket (data pushed from 
# Performance Hub to a bucket in the AP account - hence hard-coded name)
# Legacy account was arn:aws:iam::677012035582:policy/read-ap-ppas
resource "aws_iam_policy" "s3_ap_Landing_policy" {
  name   = "${local.application_name}-s3-ap-landing-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "MOJAnalyticalPlatformListBucket",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation"
            ],
            "Resource": "arn:aws:s3:::hmpps-performance-hub-landing"
        },
        {
            "Sid": "MOJAnalyticalPlatformWriteBucket",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:GetObject"
            ],
            "Resource": "arn:aws:s3:::hmpps-performance-hub-landing/*"
        }
    ]
}
EOF
}


# S3 bucket access policy for PerformanceHub landing bucket (data pushed from 
# AP to a bucket in this account
# Legacy account was arn:aws:iam::677012035582:policy/read-ap-ppas
resource "aws_iam_policy" "s3_hub_Landing_policy" {
  name   = "${local.application_name}-s3-hub-landing-policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "HubLandBucketLevel",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket"
            ],
            "Resource": [
                "${module.ap_landing_bucket.bucket.arn}"
            ]
        },
        {
            "Sid": "HubLandObjectLevel",
            "Effect": "Allow",
            "Action": [
                "s3:GetObjectAcl",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": [
                "${module.ap_landing_bucket.bucket.arn}/*"
            ]
        }
    ]
}
EOF
}