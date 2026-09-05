# Evidence Index

The screenshot numbering follows the lab workflow. Number 11 is intentionally unused because that phase installed and prepared the command-line tooling; screenshot 12 captures the combined end-to-end result.

| Number | Evidence | What it demonstrates |
|---|---|---|
| 01a | [Before database-VM decommissioning](../screenshots/01a-rg-2tier-web-before-db-decommissioning.png) | Original Lab 02 resource group with both web and database virtual machines |
| 01b | [After database-VM decommissioning](../screenshots/01b-rg-2tier-web-after-db-decommissioning.png) | Web-tier resources retained and database-VM resources removed |
| 02 | [SQL Basic tier configuration](../screenshots/02-sql-basic-tier-configuration.png) | Basic tier, 5 DTUs, 2 GB maximum size, and displayed cost estimate |
| 03 | [Azure SQL Database deployed](../screenshots/03-sql-database-deployed.png) | `sqldb-app` online on the Basic tier |
| 04a | [SQL firewall configuration](../screenshots/04a-sql-server-firewall-configuration.png) | Selected networks, firewall rule, and Azure-services exception |
| 04b | [SQL TLS configuration](../screenshots/04b-sql-server-tls-configuration.png) | Default connection policy and minimum TLS 1.2 |
| 05 | [Key Vault deployed](../screenshots/05-key-vault-deployed.png) | Vault, resource group, region, Standard tier, and recovery settings |
| 06 | [Key Vault RBAC configuration](../screenshots/06-key-vault-rbac-configuration.png) | Azure role-based access control selected |
| 07 | [User Key Vault Administrator role](../screenshots/07-user-key-vault-administrator-role.png) | Administrator role assigned at the vault resource scope |
| 08 | [SQL password secret created](../screenshots/08-sql-admin-password-secret-created.png) | `SqlAdminPassword` exists and is enabled; the value is not shown |
| 09 | [VM system-assigned identity](../screenshots/09-vm-system-assigned-managed-identity.png) | Managed identity enabled on `vm-web-01` |
| 10 | [VM Key Vault Secrets User role](../screenshots/10-vm-key-vault-secrets-user-role.png) | Least-privilege secret-reading role assigned to the VM identity |
| 12 | [Authenticated connectivity test](../screenshots/12-azure-sql-authenticated-connectivity-test.png) | Identity token, secret retrieval, SQL authentication, encrypted session, and cleanup all succeeded |
| 13 | [Azure SQL DTU monitoring](../screenshots/13-sql-database-dtu-monitoring.png) | DTU percentage monitored with Max aggregation |
| 14 | [Final Lab 03 resource group](../screenshots/14-lab03-final-resource-group.png) | Key Vault, SQL logical server, and SQL database present |

## Publication safety

The evidence set contains no password, secret value, token, connection string, SSH private key, or usable public IP address. Personal account and subscription details were redacted before publication.
