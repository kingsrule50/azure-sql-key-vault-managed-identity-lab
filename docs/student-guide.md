# Student Guide: Modernizing to Azure SQL and Securing Secrets

## What you will build

You will retain the existing `vm-web-01` Ubuntu VM from Lab 02, remove the old database VM, deploy Azure SQL Database, store the SQL password in Azure Key Vault, and let the web VM retrieve the secret through its managed identity.

**Estimated time:** 75–90 minutes

**Level:** Intermediate

**Main services:** Azure SQL Database, Azure Key Vault, Managed Identity, Azure RBAC, Azure Monitor

> Azure portal pages and prices can change. Review all settings and the cost estimate before creating resources.

## Prerequisites

- An Azure subscription with permission to create resources and role assignments.
- Lab 02 completed with `vm-web-01` still available.
- Access to the SSH private key for `vm-web-01`, or permission to add a new public key.
- A password manager for the temporary SQL administrator password.

## Resource names used in this lab

| Resource | Name |
|---|---|
| Existing resource group | `rg-2tier-web-lab` |
| Existing web VM | `vm-web-01` |
| New resource group | `rg-lab03-kingsrule` |
| SQL logical server | `sql-server-kingsrule` |
| SQL database | `sqldb-app` |
| Key Vault | `kv-lab03-kingsrule` |
| Secret | `SqlAdminPassword` |

Replace `kingsrule` with your own short identifier when names must be globally unique.

## Phase 1: Document and decommission the old database VM

1. Open `rg-2tier-web-lab` in the Azure portal.
2. Capture the original resource group showing `vm-web-01` and `vm-db-01`.
3. Delete `vm-db-01` only after confirming that it contains no required data.
4. Remove the database VM's NIC and OS disk if they were not deleted automatically.
5. Refresh the resource group.
6. Confirm the web VM, its NIC, disk, NSG, public IP, SSH key, and VNet remain.
7. Capture the post-decommissioning resource group.

Expected result: the web tier remains available and the IaaS database tier is gone.

## Phase 2: Create the Lab 03 resource group

1. Open **Resource groups** and select **Create**.
2. Select your subscription.
3. Enter `rg-lab03-kingsrule`.
4. Select **East US** for the resource-group metadata location.
5. Select **Review + create**, then **Create**.

## Phase 3: Deploy Azure SQL Database

1. Search for **SQL databases** and select **Create**.
2. Choose `rg-lab03-kingsrule`.
3. Enter `sqldb-app` as the database name.
4. Under **Server**, select **Create new**.
5. Enter a globally unique server name such as `sql-server-kingsrule`.
6. Choose an available region. This lab used West US 2 because East US was unavailable to the subscription.
7. Select **Use SQL authentication**.
8. Enter `sqladmin` as the administrator login and create a strong temporary password.
9. Store the password in a password manager. Do not put it in a script, screenshot, or Git repository.
10. Open **Configure database** and select the DTU purchasing model.
11. Choose **Basic**, 5 DTUs, and 2 GB maximum data size.
12. On **Networking**, choose **Public endpoint** and **Selected networks**.
13. Add your workstation IP only if direct workstation access is required.
14. For this temporary lab, enable **Allow Azure services and resources to access this server**.
15. Keep the default connection policy and require TLS 1.2.
16. Do not enable optional paid security features unless you intend to use them.
17. Review the cost, create the database, and wait for deployment to finish.
18. Open `sqldb-app` and confirm **Status: Online** and **Pricing tier: Basic**.

## Phase 4: Verify SQL network and TLS settings

1. From `sqldb-app`, open the linked SQL server.
2. Open **Security > Networking > Public access**.
3. Confirm **Selected networks** is enabled.
4. Confirm the required firewall rule and the Azure-services exception are present.
5. Open **Connectivity**.
6. Confirm the connection policy is **Default**.
7. Confirm the minimum TLS version is **TLS 1.2**.

> The Azure-services exception is intentionally broad for this lab. Prefer private endpoints or tightly scoped network rules in production.

## Phase 5: Deploy Azure Key Vault

1. Search for **Key vaults** and select **Create**.
2. Choose `rg-lab03-kingsrule`.
3. Enter `kv-lab03-kingsrule` or another globally unique name.
4. Select **East US** and the **Standard** pricing tier.
5. Keep soft delete enabled.
6. Purge protection may remain disabled only because this is a temporary training lab.
7. Under **Access configuration**, select **Azure role-based access control**.
8. Leave the resource-access checkboxes unchecked.
9. Create and open the vault.

## Phase 6: Grant your user administrative access

1. Open the Key Vault's **Access control (IAM)** page.
2. Select **Add > Add role assignment**.
3. Select **Key Vault Administrator**.
4. Assign the role to your own Azure user at **This resource** scope.
5. Select **Review + assign** and allow a few minutes for propagation.

## Phase 7: Create the password secret

1. Open **Objects > Secrets** in the Key Vault.
2. Select **Generate/Import**.
3. Enter `SqlAdminPassword` as the name.
4. Paste the same SQL administrator password used when the SQL server was created.
5. Select **Create**.
6. Confirm the secret is **Enabled** without opening or displaying its value.

## Phase 8: Enable the VM managed identity

1. Open `vm-web-01`.
2. Select **Security > Identity**.
3. On **System assigned**, change **Status** to **On**.
4. Select **Save** and confirm the operation.

## Phase 9: Give the VM least-privilege secret access

1. Return to the Key Vault's **Access control (IAM)** page.
2. Add the **Key Vault Secrets User** role.
3. For **Assign access to**, choose **Managed identity**.
4. Select **Virtual machine**, then select `vm-web-01`.
5. Assign the role at the Key Vault resource scope.

Do not give the VM the `Key Vault Administrator` role. The VM needs to read the secret value, not administer the vault.

## Phase 10: Connect to the web VM

Replace the placeholder with the VM's current public IP:

```bash
ssh -i ~/.ssh/vm_web_01_kingsrule_wsl azureuser@<VM-PUBLIC-IP>
```

Verify the session:

```bash
hostname
whoami
```

Expected output: `vm-web-01` and `azureuser`.

## Phase 11: Install sqlcmd on Ubuntu 24.04

Run each command on the VM:

```bash
curl -fsSLo /tmp/packages-microsoft-prod.deb \
  https://packages.microsoft.com/config/ubuntu/24.04/packages-microsoft-prod.deb

sudo dpkg -i /tmp/packages-microsoft-prod.deb
sudo apt-get update
sudo env ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
rm -f /tmp/packages-microsoft-prod.deb
```

Verify the executable:

```bash
test -x /opt/mssql-tools18/bin/sqlcmd \
  && echo "PASS: sqlcmd installed successfully." \
  || echo "FAIL: sqlcmd installation not found."
```

## Phase 12: Validate secure connectivity

Copy [the validation script](../scripts/validate-secure-sql.sh) to `vm-web-01`, then run:

```bash
chmod 700 validate-secure-sql.sh
./validate-secure-sql.sh
```

Expected results:

- Managed identity token acquired.
- `SqlAdminPassword` retrieved from Key Vault without displaying it.
- Azure SQL query succeeds as `sqladmin` against `sqldb-app`.
- The connection reports `Encrypted = TRUE`.
- The token, password, and temporary response are removed.

## Phase 13: Review Azure SQL monitoring

1. Open `sqldb-app` in the Azure portal.
2. Select **Monitoring > Metrics**.
3. Choose **DTU percentage**.
4. Set aggregation to **Max**.
5. Set the time range to **Last 24 hours**.
6. Confirm that the chart displays data.

## Phase 14: Final verification

Confirm all of the following before cleanup:

| Verification | Expected result |
|---|---|
| Azure SQL | `sqldb-app` is Online on Basic 5 DTUs |
| Key Vault | `SqlAdminPassword` is Enabled |
| Permission model | Azure RBAC |
| VM identity | System assigned is On |
| VM role | `Key Vault Secrets User` at vault scope |
| Secret test | VM retrieves the secret without displaying it |
| SQL test | Authenticated query succeeds with `Encrypted = TRUE` |
| Monitoring | DTU chart displays data |

## Troubleshooting

| Problem | Resolution |
|---|---|
| SQL region unavailable | Choose a permitted region and record the actual location. |
| Basic tier missing | Remove any free-offer selection and choose the DTU purchasing model. |
| Key Vault shows unauthorized | Confirm your `Key Vault Administrator` assignment and wait for RBAC propagation. |
| VM is missing from the identity picker | Enable and save the VM's system-assigned identity, then wait briefly. |
| Key Vault returns HTTP 403 | Confirm the VM has `Key Vault Secrets User` at the vault scope. |
| TCP 1433 is unreachable | Review SQL public access, firewall rules, and the Azure-services exception. |
| `sqlcmd` is not found | Use `/opt/mssql-tools18/bin/sqlcmd` or reinstall `mssql-tools18`. |
| SQL login fails | Verify the login, database name, and password stored in Key Vault. |

## Cleanup

After capturing and safely redacting the evidence:

1. Delete `rg-lab03-kingsrule`.
2. Purge the deleted Key Vault only if you need to reuse its name and purge protection is disabled.
3. Delete `rg-2tier-web-lab` when the earlier Lab 02 environment is no longer required.
4. Confirm that the VMs, disks, NICs, NSGs, public IP, SSH key resource, VNet, SQL resources, and Key Vault are removed.

Deleting the VM removes its system-assigned managed identity. Deleting the Key Vault removes its resource-scoped role assignments.

## What you learned

You replaced an IaaS database VM with Azure SQL Database, protected the database password in Key Vault, used Azure RBAC and managed identity for secret access, validated an encrypted database session, and monitored database utilization through Azure Monitor.
