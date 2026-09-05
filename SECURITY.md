# Security Policy

## Project scope

This repository documents a temporary Azure portfolio environment. It contains no active credentials and should not be treated as a production deployment template.

## Never commit

- Passwords or Azure Key Vault secret values
- Access tokens, refresh tokens, or signed-in session data
- Connection strings containing credentials
- SSH private keys, certificates containing private keys, or `.env` files
- Terraform state files or variable files containing sensitive values
- Unredacted personal email addresses, public IP addresses, or subscription identifiers

The included `.gitignore` blocks common credential and state-file patterns, but it is not a substitute for reviewing every change before committing.

## Lab security decisions

- The VM uses a system-assigned managed identity to authenticate to Key Vault.
- The VM receives only `Key Vault Secrets User` at the Key Vault resource scope.
- The SQL password is retrieved at runtime and is never printed by the validation script.
- `SQLCMDPASSWORD` keeps the password out of the `sqlcmd` command line.
- The SQL connection requests encryption, and the query confirms `Encrypted = TRUE`.
- The token, password variable, and temporary Key Vault response are removed when the script exits.

## Production recommendations

Before adapting this design for production, evaluate private endpoints, Microsoft Entra authentication for Azure SQL, Key Vault purge protection, restricted Key Vault networking, diagnostic settings, centralized logging, backup requirements, policy enforcement, and a tested recovery plan.

## Reporting a problem

If you find sensitive information in this repository, do not open a public issue containing the data. Contact the repository owner privately through the contact method listed on the owner's GitHub profile.
