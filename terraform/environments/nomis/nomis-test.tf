# nomis-test environment settings
locals {
  nomis_test = {
    # ip ranges for external access to database instances
    database_external_access_cidr = [
      local.cidrs.noms_test,
      local.cidrs.noms_mgmt,
      local.cidrs.cloud_platform
    ]

    # vars common across ec2 instances
    ec2_common = {
      public_key                = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCv/RZr7NQwO1Ovjbaxs5X9jR1L4QU/WSOIH3qhCriTlzbdnPI5mA79ZWBZ25h5tA2eIu5FbX+DBwYgwARCnS6VL4KiLKq9j7Ys/gx2FE6rWlXEibpK/9dGLu35znDUyO0xiLIu/EPZFpWhn/2L1z82GiEjDaiY00NmxkHHKMaRCDrgCJ4tEhGPWGcPYoNAYmCkncQJjYojSJ0uaP6e85yx2nmE85YDE+QcDoN5HtHex84CCibh98nD2tMhEQ2Ss+g7/nSXw+/Z2RadDznpz0h/8CcgAGpTHJ35+aeWINquw0lWSJldCLfn3PXldcDzFleqoop9jRGn2hB9eOUz2iEC7MXoLPFcen/lzQD+xfwvaq1+4YU7BbiyTtY/lcw0xcE01QBA+nUiHPJMBewr2TmZRHNy1fvg8ZRKLrOcEMz8iPKVtquftl1DZZCO8Xccr3BVpfoXIl5LuEWPqnMABAvgtkHMaIkTqKMgaKVEC9/KTqRn/K2zzGljUJkzcgO95bNksjDRXtbfQ0AD7CLa47xPOLPh4dC2WDindKh3YALa74EBOyEtJWvLt6fRLPhWmOaZkCrjC3TI+onKiPo0nXrN7Uyg2Q6Atiauw6fqz63cRXkzU/e7LVoxT42qaaaGMytgZJXF3Wk4hp88IqqnDXFavLUElsJEgOTWiNTk2N92/w=="
      patch_approval_delay_days = 3
      patch_day                 = "TUE"
    }

    # cloud watch log groups
    log_groups = {
      session-manager-logs = {
        retention_days = 90
      }
      cwagent-var-log-messages = {
        retention_days = 30
      }
      cwagent-var-log-secure = {
        retention_days = 90
      }
      cwagent-nomis-autologoff = {
        retention_days = 90
      }
    }

    # Legacy database module, do not add any more entries here
    databases_legacy = {
      CNOMT1 = {
        always_on          = false
        ami_name           = "nomis_db_STIG_CNOMT1-2022-04-21*"
        asm_data_capacity  = 100
        asm_flash_capacity = 2
        description        = "Test NOMIS T1 database with a dataset of T1PDL0009 (note: only NOMIS db, NDH db is not included."
        tags = {
          monitored = false
        }
      }
    }

    # Add database instances here. They will be created using ec2-database.tf
    databases = {
      # Naming
      # *-nomis-db-1: NOMIS, NDH, TRDATA
      # *-nomis-db-2: MIS, AUDIT
      # *-nomis-db-3: HA

      t1-nomis-db-2 = {
        tags = {
          server-type         = "nomis-db"
          description         = "T1 NOMIS Audit database to replace Azure T1PDL0010"
          oracle-sids         = "T1CNMAUD"
          monitored           = false
          always-on           = true
          instance-scheduling = "skip-scheduling"
        }
        ami_name  = "nomis_rhel_7_9_oracledb_11_2_release_2022-10-07T12-48-08.562Z"
        ami_owner = "self" # remove this line next time AMI is updated so core-shared-services-production used instead
        instance = {
          disable_api_termination = true
        }
        ebs_volumes = {
          "/dev/sdb" = {       # /u01
            iops       = 300   # Temporary. See DSOS-1561
            throughput = 0     # Temporary. See DSOS-1561
            type       = "gp2" # Temporary. See DSOS-1561
            size       = 100
          }
          "/dev/sdc" = {       # /u02
            iops       = 300   # Temporary. See DSOS-1561
            throughput = 0     # Temporary. See DSOS-1561
            type       = "gp2" # Temporary. See DSOS-1561
            size       = 100
          }
        }
        ebs_volume_config = {
          app = {
            iops       = 3000  # Temporary. See DSOS-1561
            throughput = 0     # Temporary. See DSOS-1561
            type       = "gp2" # Temporary. See DSOS-1561
          }
          data = {
            iops       = 120   # Temporary. See DSOS-1561
            throughput = 0     # Temporary. See DSOS-1561
            type       = "gp2" # Temporary. See DSOS-1561
            total_size = 200
          }
          flash = {
            iops       = 100   # Temporary. See DSOS-1561
            throughput = 0     # Temporary. See DSOS-1561
            type       = "gp2" # Temporary. See DSOS-1561
            total_size = 2
          }
          swap = {
            iops       = 100   # Temporary. See DSOS-1561
            throughput = 0     # Temporary. See DSOS-1561
            type       = "gp2" # Temporary. See DSOS-1561
          }
        }
      }
    }

    # Add weblogic instances here
    weblogic_autoscaling_groups = {
      t1-nomis-web = {
        tags = {
          oracle-db-hostname = "db.CNOMT1.nomis.hmpps-test.modernisation-platform.internal"
          oracle-sid         = "CNOMT1"
        }
        ami_name = "nomis_rhel_6_10_weblogic_appserver_10_3_release_2022-11-02T00-00-24.828Z"
        # branch = var.BRANCH_NAME # comment in if testing ansible

        # NOTE: setting desired capacity to 0 as this is not fully working yet
        # See DSOS-1570 and DSOS-1571
        autoscaling_group = {
          desired_capacity = 0
        }
        offpeak_desired_capacity = 0
      }
    }

    # Legacy weblogic, to be zapped imminently
    weblogics = {
      CNOMT1 = {
        ami_name     = "nomis_Weblogic_2022*"
        asg_max_size = 1
      }
    }

    ec2_test_instances = {
      t1-ndh-app = {
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH App"
          monitored   = false
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
      t1-ndh-ems = {
        tags = {
          description = "Standalone EC2 for testing RHEL7.9 NDH EMS"
          monitored   = false
        }
        ami_name = "nomis_rhel_7_9_baseimage_2022-11-01T13-43-46.384Z"
        # branch   = var.BRANCH_NAME # comment in if testing ansible
      }
    }
  }
}
