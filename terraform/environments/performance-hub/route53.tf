# Note: The production record is managed by operations engineering and has a CNAME to this record
resource "aws_route53_record" "external" {
  provider = aws.core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.external.dns_name
    zone_id                = aws_lb.external.zone_id
    evaluate_target_health = true
  }
}

# Note: Production certificate is a Gandi cert which is manually imported
resource "aws_acm_certificate" "external" {
  count             = local.is-production ? 0 : 1
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["*.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = local.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "external_validation" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-network-services

  allow_overwrite = true
  name            = local.domain_name_main[0]
  records         = local.domain_record_main
  ttl             = 60
  type            = local.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  count    = local.is-production ? 0 : 1
  provider = aws.core-vpc

  allow_overwrite = true
  name            = local.domain_name_sub[0]
  records         = local.domain_record_sub
  ttl             = 60
  type            = local.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

resource "aws_acm_certificate_validation" "external" {
  count                   = local.is-production ? 0 : 1
  certificate_arn         = aws_acm_certificate.external[0].arn
  validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
}
