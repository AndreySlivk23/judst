locals {

  weblogic_ssm_parameters = {
    parameters = {
      passwords = { description = "weblogic passwords" }
      rms       = { description = "combined reporting secrets" }
    }
  }

  weblogic_ssm_parameters_old = {
    prefix = "/weblogic/"
    parameters = {
      admin_username     = { description = "weblogic admin username" }
      admin_password     = { description = "weblogic admin password" }
      db_username        = { description = "nomis database username" }
      db_password        = { description = "nomis database password" }
      db_tagsar_username = { description = "nomis database tag username" }
      db_tagsar_password = { description = "nomis database tag password" }
      rms_hosts          = { description = "combined reporting host list" }
      rms_key            = { description = "combined reporting rms key" }
    }
  }

  weblogic_target_group_http_7001 = {
    port                 = 7001
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/"
      port                = 7001
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  weblogic_target_group_http_7777 = {
    port                 = 7777
    protocol             = "HTTP"
    target_type          = "instance"
    deregistration_delay = 30
    health_check = {
      enabled             = true
      interval            = 30
      healthy_threshold   = 3
      matcher             = "200-399"
      path                = "/keepalive.htm"
      port                = 7777
      timeout             = 5
      unhealthy_threshold = 5
    }
    stickiness = {
      enabled = true
      type    = "lb_cookie"
    }
  }

  weblogic_lb_listeners = {

    http = {
      port     = 80
      protocol = "HTTP"

      default_action = {
        type = "redirect"
        redirect = {
          port        = 443
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }

    http7777 = {
      port     = 7777
      protocol = "HTTP"

      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not implemented"
          status_code  = "501"
        }
      }
    }

    https = {
      port                      = 443
      protocol                  = "HTTPS"
      ssl_policy                = "ELBSecurityPolicy-2016-08"
      certificate_names_or_arns = ["nomis_wildcard_cert"]
      cloudwatch_metric_alarms  = module.baseline_presets.cloudwatch_metric_alarms.lb

      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not implemented"
          status_code  = "501"
        }
      }
    }

  }

  # TODO - change alarm actions to dba_pagerduty once alarms proven out
  weblogic_cloudwatch_metric_alarms = merge(
    module.baseline_presets.cloudwatch_metric_alarms.ec2,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_cwagent_linux,
    module.baseline_presets.cloudwatch_metric_alarms.ec2_instance_cwagent_collectd,
    {
      weblogic-healthcheck = {
        comparison_operator = "GreaterThanOrEqualToThreshold"
        evaluation_periods  = "3"
        namespace           = "CWAgent"
        metric_name         = "collectd_weblogichealthcheck_value"
        period              = "60"
        statistic           = "Average"
        threshold           = "1"
        alarm_description   = "weblogic-healthcheck has found an unhealthy service"
        alarm_actions       = ["dso_pagerduty"]
      }
    }
  )

  weblogic_cloudwatch_log_groups = {
    cwagent-weblogic-logs = {
      retention_in_days = 30
    }
  }

  weblogic_ec2 = {

    # cloudwatch_metric_alarms = local.weblogic_cloudwatch_metric_alarms

    # Note: use any availability zone since DB latency does not appear to be an issue
    config = merge(module.baseline_presets.ec2_instance.config.default, {
      ami_name                  = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2023-03-15T17-18-22.178Z"
      availability_zone         = null
      ssm_parameters_prefix     = "weblogic/"
      iam_resource_names_prefix = "ec2-weblogic"
    })

    instance = merge(module.baseline_presets.ec2_instance.instance.default_rhel6, {
      instance_type          = "t2.large"
      vpc_security_group_ids = ["private-web"]
    })

    user_data_cloud_init = module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible

    autoscaling_group = module.baseline_presets.ec2_autoscaling_group.default

    lb_target_groups = {
      http-7777 = local.weblogic_target_group_http_7777
    }

    tags = {
      ami         = "nomis_rhel_6_10_weblogic_appserver_10_3"
      backup      = "false" # disable mod platform backup since everything is in code
      description = "nomis weblogic appserver 10.3"
      os-type     = "Linux"
      server-type = "nomis-web"
      component   = "web"
    }
  }
}
