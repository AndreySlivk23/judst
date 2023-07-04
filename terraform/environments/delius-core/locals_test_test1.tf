# Terraform configuration data for environments in delius-core test account

# Sample data
# tags demonstrate inheritance due to merges in the module
locals {
  ldap_config_test1 = {
    name                 = "ldap"
    some_other_attribute = "some_other_attribute_for_ldap_in_test1"
  }

  db_config_test1 = {
    name                 = "db"
    some_other_attribute = "some_other_attribute_for_db_in_test1"
  }
}
