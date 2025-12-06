provider "aws" {
  region = "us-east-1"
}

locals {
  tables = {
    example1 = {
      table_name = "example-messages"
      hash_key   = "message_id"
      range_key  = "account_id"
      billing_mode = "PAY_PER_REQUEST"
      table_class = "STANDARD"
      point_in_time_recovery_enabled = true
      attributes = [
        { name = "message_id", type = "S" },
        { name = "account_id", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name            = "AccountIndex"
          hash_key        = "account_id"
          projection_type = "ALL"
        }
      ]
    }

    example2 = {
      table_name = "example-accounts"
      hash_key   = "account_id"
      range_key  = "created_at"
      billing_mode = "PAY_PER_REQUEST"
      table_class = "STANDARD"
      point_in_time_recovery_enabled = true
      attributes = [
        { name = "account_id", type = "S" },
        { name = "created_at", type = "S" }
      ]
      global_secondary_indexes = [
        {
          name            = "CreatedAtIndex"
          hash_key        = "created_at"
          projection_type = "ALL"
        }
      ]
    }
  }
}

module "dynamodb_table" {
  source = "../"

  for_each = local.tables

  name                            = each.value.table_name
  hash_key                        = each.value.hash_key
  range_key                       = lookup(each.value, "range_key", null)
  table_class                     = lookup(each.value, "table_class", "STANDARD")
  billing_mode                    = lookup(each.value, "billing_mode", "PAY_PER_REQUEST")
  deletion_protection_enabled     = false
  point_in_time_recovery_enabled  = lookup(each.value, "point_in_time_recovery_enabled", false)
  attributes                      = each.value.attributes
  global_secondary_indexes        = lookup(each.value, "global_secondary_indexes", [])

  tags = {
    Terraform   = "true"
    Environment = "test"
  }
}
