locals {
  ldap_config_lower_environments = {
    name                        = "ldap_for_lower_environments"
    migration_source_account_id = local.application_data.accounts[local.environment].migration_source_account_id # legacy pre-prod account
    migration_lambda_role       = "ldap-data-migration-lambda-role" # IAM role in legacy pre-prod account
    some_other_attribute        = "some_other_attribute_for_ldap_from_lower_environment_config"
  }

  db_config_lower_environments = {
    name                 = "db_for_lower_environments"
    ami_name             = "delius_core_ol_8_5_oracle_db_19c_patch_2023-06-12T12-32-07.259Z"
    some_other_attribute = "some_other_attribute_for_db_from_lower_environment_config"
  }
}
