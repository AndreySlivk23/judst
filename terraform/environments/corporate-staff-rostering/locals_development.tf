# nomis-development environment settings
locals {

  # baseline config
  development_config = {

    baseline_ec2_autoscaling_groups = {
      dev-base-ol85 = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "base_ol_8_5_*"
          availability_zone = null
        })
        instance = merge(module.baseline_presets.ec2_instance.instance.default, {
          vpc_security_group_ids = ["data-db"]
        })
        user_data_cloud_init = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible, {
          args = merge(module.baseline_presets.ec2_instance.user_data_cloud_init.ssm_agent_and_ansible.args, {
            branch = "main"
          })
        })
        autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 0
        })
        # autoscaling_schedules = module.baseline_presets.ec2_autoscaling_schedules.working_hours
        tags = {
          description = "For testing our base OL8.5 base image"
          ami         = "base_ol_8_5"
          os-type     = "Linux"
          component   = "test"
          server-type = "base-ol-8-5"
        }
      }
    }, 

    windows_autoscaling_group = {
      dev-base-windows = {
        config = merge(module.baseline_presets.ec2_instance.config.default, {
          ami_name          = "ami-0a95a55db30f2dc58"
          availability_zone = null
          ami_owner = "Microsoft"
        })

      autoscaling_group = merge(module.baseline_presets.ec2_autoscaling_group.default, {
          desired_capacity = 1
        })
      tags = {
          description = "For testing our base windows image"
          ami         = "ami-0a95a55db30f2dc58"
          os-type     = "Windows"
          component   = "test"
          server-type = "ami-0a95a55db30f2dc58"
        }
      }
    }

  }

}
