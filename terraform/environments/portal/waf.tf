data "local_file" "portal_whitelist" {
  filename = "aws_waf_ipset.txt"
}

resource "aws_wafv2_ip_set" "portal_whitelist" {
  name               = "portal_whitelist"
  description        = "List of Internal MOJ Addresses that are whitelisted. Comments above the relevant IPs shows where they arehttps://github.com/ministryofjustice/moj-ip-addresses/blob/master/moj-cidr-addresses.yml"
  scope              = "CLOUDFRONT"
  ip_address_version = "IPV4"
  addresses          = [data.local_file.portal_whitelist.content]
}

resource "aws_wafv2_web_acl" "wafv2_acl" {
name            = "${upper(local.application_name)}-WebAcl"
scope           = "CLOUDFRONT"

dynamic "default_action" {
  for_each = local.environment == "production" ? [1] : []
  content {
    allow {}
  }
}

dynamic "default_action" {
  for_each = local.environment != "production" ? [1] : []
  content {
    block {}
  }
}

visibility_config {
  cloudwatch_metrics_enabled = true
  metric_name                = "PortalWebRequests"
  sampled_requests_enabled   = true
}

#This rule is NOT required in Production
rule {
    name     = "WhitelistInternalMoJAndPingdom"
    priority = 4
    action {
      allow {}
      }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "PortalManualAllowRuleMetric"
      sampled_requests_enabled   = true
    }
    statement {
        ip_set_reference_statement {
          arn = aws_wafv2_ip_set.portal_whitelist.arn
        }
      }
}

rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 0

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleMetric"
      sampled_requests_enabled   = true
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "GenericRFI_QUERYARGUMENTS"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "CrossSiteScripting_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "CrossSiteScripting_COOKIE"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "SizeRestrictions_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "GenericRFI_BODY"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "CrossSiteScripting_QUERYARGUMENTS"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "NoUserAgent_HEADER"
        }

      }
    }
}

rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleMetric"
      sampled_requests_enabled   = true
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
}

rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 2

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesAmazonIpReputationListMetric"
      sampled_requests_enabled   = true
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
}

rule {
    name     = "AWSManagedRulesBotControl"
    priority = 3

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesBotControlMetric"
      sampled_requests_enabled   = true
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }
}
}



