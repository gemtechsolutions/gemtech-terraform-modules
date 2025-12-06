# Cognito Module

This Terraform module creates a Cognito user pool, clients, users, and groups.

## Features

- User Pool and domain
- OAuth 2.0 app clients
- Predefined user groups
- Optional users
- Optional MFA and advanced security settings

## Inputs

Refer to `variables.tf` for full configuration options.

## Outputs

- `user_pool_id` – ID of the Cognito user pool
- `user_pool_arn` – ARN of the Cognito user pool
- `client_ids` – Map of client names to their IDs
