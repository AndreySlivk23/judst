// DEV + PRE-PRODUCTION DNS CONFIGURATION

// ACM Public Certificate
resource "aws_acm_certificate" "external" {
  domain_name       = "modernisation-platform.service.justice.gov.uk"
  validation_method = "DNS"

  subject_alternative_names = ["${var.app_name}.${var.networking_business_unit}-${tribunal_locals.environment}.modernisation-platform.service.justice.gov.uk"]
  tags = {
    Environment = tribunal_locals.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "external" {
  certificate_arn         = aws_acm_certificate.external.arn
  validation_record_fqdns = [tribunal_locals.domain_name_main[0], tribunal_locals.domain_name_sub[0]]
}

// Route53 DNS records for certificate validation
resource "aws_route53_record" "external_validation" {
  provider = core-network-services

  allow_overwrite = true
  name            = tribunal_locals.domain_name_main[0]
  records         = tribunal_locals.domain_record_main
  ttl             = 60
  type            = tribunal_locals.domain_type_main[0]
  zone_id         = data.aws_route53_zone.network-services.zone_id
}

resource "aws_route53_record" "external_validation_subdomain" {
  provider = core-vpc

  allow_overwrite = true
  name            = tribunal_locals.domain_name_sub[0]
  records         = tribunal_locals.domain_record_sub
  ttl             = 60
  type            = tribunal_locals.domain_type_sub[0]
  zone_id         = data.aws_route53_zone.external.zone_id
}

// Route53 DNS record for directing traffic to the service
resource "aws_route53_record" "external" {
  provider = core-vpc

  zone_id = data.aws_route53_zone.external.zone_id
  name    = "${var.networking[0].application}.${var.networking[0].business-unit}-${tribunal_locals.environment}.modernisation-platform.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}

// PRODUCTION DNS CONFIGURATION

// ACM Public Certificate
resource "aws_acm_certificate" "external_prod" {
  count = tribunal_locals.is-production ? 1 : 0

  domain_name       = "${var.app_name}.service.justice.gov.uk"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "external_prod" {
  count = tribunal_locals.is-production ? 1 : 0

  certificate_arn         = aws_acm_certificate.external_prod[0].arn
  validation_record_fqdns = [aws_route53_record.external_validation_prod[0].fqdn]
  timeouts {
    create = "10m"
  }
}

// Route53 DNS record for certificate validation
resource "aws_route53_record" "external_validation_prod" {
  count    = tribunal_locals.is-production ? 1 : 0
  provider = aws.core-network-services

  allow_overwrite = true
  name            = tolist(aws_acm_certificate.external_prod[0].domain_validation_options)[0].resource_record_name
  records         = [tolist(aws_acm_certificate.external_prod[0].domain_validation_options)[0].resource_record_value]
  type            = tolist(aws_acm_certificate.external_prod[0].domain_validation_options)[0].resource_record_type
  zone_id         = data.aws_route53_zone.application_zone.zone_id
  ttl             = 60
}

// Route53 DNS record for directing traffic to the service
resource "aws_route53_record" "external_prod" {
  count    = tribunal_locals.is-production ? 1 : 0
  provider = aws.core-network-services

  zone_id = data.aws_route53_zone.application_zone.zone_id
  name    = "${var.app_name}.service.justice.gov.uk"
  type    = "A"

  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}
