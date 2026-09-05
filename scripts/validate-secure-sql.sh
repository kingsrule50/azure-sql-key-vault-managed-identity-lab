#!/usr/bin/env bash
set -euo pipefail
umask 077

# Override any of these values with environment variables when reusing the lab.
KEY_VAULT_NAME="${KEY_VAULT_NAME:-kv-lab03-kingsrule}"
SECRET_NAME="${SECRET_NAME:-SqlAdminPassword}"
SQL_SERVER="${SQL_SERVER:-sql-server-kingsrule.database.windows.net}"
SQL_DATABASE="${SQL_DATABASE:-sqldb-app}"
SQL_USERNAME="${SQL_USERNAME:-sqladmin}"
SQLCMD="${SQLCMD:-/opt/mssql-tools18/bin/sqlcmd}"

KV_TOKEN=""
SQL_PASSWORD=""
KV_RESPONSE_FILE=""

cleanup() {
  unset KV_TOKEN SQL_PASSWORD SQLCMDPASSWORD
  if [[ -n "${KV_RESPONSE_FILE:-}" && -f "$KV_RESPONSE_FILE" ]]; then
    rm -f -- "$KV_RESPONSE_FILE"
  fi
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || fail "curl is required."
command -v python3 >/dev/null 2>&1 || fail "python3 is required."
[[ -x "$SQLCMD" ]] || fail "sqlcmd was not found at $SQLCMD."

echo "Secure Azure SQL Connectivity Validation"
echo "========================================"

KV_TOKEN=$(
  curl -fsS -H "Metadata: true" \
    "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net" \
  | python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
)
[[ -n "$KV_TOKEN" ]] || fail "Managed identity token missing."
echo "PASS: Managed identity token acquired."

KV_RESPONSE_FILE=$(mktemp /tmp/keyvault-response.XXXXXX)
KV_HTTP_CODE=$(
  curl -sS -o "$KV_RESPONSE_FILE" -w "%{http_code}" \
    -H "Authorization: Bearer $KV_TOKEN" \
    "https://${KEY_VAULT_NAME}.vault.azure.net/secrets/${SECRET_NAME}?api-version=7.4"
)
[[ "$KV_HTTP_CODE" == "200" ]] || fail "Key Vault returned HTTP $KV_HTTP_CODE."

SQL_PASSWORD=$(
  python3 - "$KV_RESPONSE_FILE" <<'PY'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as response:
    print(json.load(response)["value"])
PY
)
[[ -n "$SQL_PASSWORD" ]] || fail "SQL password missing."
echo "PASS: SqlAdminPassword retrieved securely from Key Vault."
echo
echo "Authenticated SQL query results"
echo "-------------------------------"

# SQLCMDPASSWORD keeps the password out of the process command line.
export SQLCMDPASSWORD="$SQL_PASSWORD"
"$SQLCMD" \
  -S "tcp:${SQL_SERVER},1433" \
  -d "$SQL_DATABASE" \
  -U "$SQL_USERNAME" \
  -N -l 30 -b -W -s " | " \
  -Q "
SET NOCOUNT ON;
SELECT CAST(SERVERPROPERTY('ServerName') AS nvarchar(128)) AS LogicalServer,
       DB_NAME() AS DatabaseName,
       SUSER_SNAME() AS LoginName,
       (SELECT encrypt_option
          FROM sys.dm_exec_connections
         WHERE session_id = @@SPID) AS Encrypted;"

unset KV_TOKEN SQL_PASSWORD SQLCMDPASSWORD
rm -f -- "$KV_RESPONSE_FILE"
KV_RESPONSE_FILE=""

echo
echo "PASS: Authenticated encrypted query succeeded."
echo "PASS: Token, password, and temporary response removed."
