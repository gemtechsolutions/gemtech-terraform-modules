# Cognito Module

This Terraform module creates a Cognito user pool, clients, users, and groups.

## Features

- User Pool and domain
- OAuth 2.0 app clients
- Predefined user groups
- Optional users
- Optional MFA and advanced security settings
- Optional sign-in by email (`username_attributes = ["email"]`) and auto-verified attributes. Changing `username_attributes` on an existing pool replaces it, so set it before the pool has users.
- Optional verification email body (`email_message`, must contain `{####}`), next to `email_subject`. Unset keeps the pool's current message; changing it updates the pool in place.

## Inputs

Refer to `variables.tf` for full configuration options.

## Outputs

- `user_pool_id` – ID of the Cognito user pool
- `user_pool_arn` – ARN of the Cognito user pool
- `client_ids` – Map of client names to their IDs
