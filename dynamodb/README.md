# DynamoDB Table Module

This Terraform module manages the creation of **DynamoDB tables** in AWS, with optional support for range keys, global secondary indexes, point-in-time recovery, and flexible billing and table class options.

## 📦 Module Features

- Create one or multiple DynamoDB tables using `for_each`
- Configure hash and range keys
- Add any number of attributes
- Configure Global Secondary Indexes (GSIs)
- Supports `PAY_PER_REQUEST` or `PROVISIONED` billing modes
- Enable point-in-time recovery
- Tag resources for environment tracking

## 🛠 Usage

### ➤ Basic Example (Single Table)

```hcl
module "dynamodb_table" {
  source = "git::https://github.com/YOUR_ORG/terraform-modules.git//dynamodb-table?ref=main"

  name       = "example-table"
  hash_key   = "user_id"
  attributes = [
    { name = "user_id", type = "S" }
  ]

  tags = {
    Environment = "dev"
  }
}
```

### ➤ Advanced Example (Multiple Tables)

See the [`examples/multiple`](./examples/multiple) folder for a working multi-table setup.

## 📥 Inputs

| Name                          | Type                                                                 | Description                                         | Default         |
|-------------------------------|----------------------------------------------------------------------|-----------------------------------------------------|-----------------|
| `name`                        | `string`                                                             | Name of the DynamoDB table                          | —               |
| `hash_key`                    | `string`                                                             | Hash key of the table                               | —               |
| `range_key`                   | `string`                                                             | (Optional) Range key                                | `null`          |
| `table_class`                 | `string`                                                             | Table class                                         | `"STANDARD"`    |
| `billing_mode`                | `string`                                                             | Billing mode                                        | `"PAY_PER_REQUEST"` |
| `deletion_protection_enabled`| `bool`                                                               | Prevent accidental deletions                        | `false`         |
| `point_in_time_recovery_enabled` | `bool`                                                          | Enables point-in-time recovery                      | `false`         |
| `attributes`                  | `list(object({ name = string, type = string }))`                    | List of attributes to define                        | —               |
| `global_secondary_indexes`    | `list(object)`                                                       | List of GSIs to create                              | `[]`            |
| `tags`                        | `map(string)`                                                        | Tags to apply to the table                          | `{}`            |

## 📤 Outputs

| Name                  | Description                          |
|-----------------------|--------------------------------------|
| `dynamodb_table_arn`  | ARN of the DynamoDB table            |
| `dynamodb_table_id`   | Name (ID) of the DynamoDB table      |

## 📁 Examples

- [`examples/multiple`](./examples/multiple): Create multiple tables using `for_each`

## 🧪 Requirements

| Name      | Version     |
|-----------|-------------|
| Terraform | >= 1.0      |
| AWS       | >= 4.0      |

## 📝 License

MIT — feel free to use and contribute.
