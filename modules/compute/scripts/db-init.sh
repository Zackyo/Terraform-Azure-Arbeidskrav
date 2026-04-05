#!/bin/bash
# =============================================================================
# db-init.sh — cloud-init-skript for DB-VM-er
# Kjøres automatisk ved første oppstart via Azure custom_data
#
# Installerer: MySQL Server 8.0
# Oppretter: database, applikasjonsbruker, products-tabell og demodata
# Konfigurerer: MySQL til å lytte på 0.0.0.0
#
# Malvariabler injisert av Terraform:
#   ${mysql_root_password}
#   ${mysql_database_name}
#   ${mysql_app_user}
#   ${mysql_app_password}
#   ${vm_index} — 1 eller 2, brukes til å merke hvilken server som leverte data
# =============================================================================

set -euo pipefail
exec > /var/log/db-init.log 2>&1
echo "[$(date)] Starter initialisering av DB-server (VM-indeks: ${vm_index})..."

VM_INDEX="${vm_index}"

# ── Vent på apt-lås ───────────────────────────────────────────────────────────
sleep 30
while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "[$(date)] Venter på apt-lås..."
  sleep 10
done

# ── Installer MySQL ───────────────────────────────────────────────────────────
export DEBIAN_FRONTEND=noninteractive

# Forhåndssetter root-passord for å unngå interaktive spørsmål
debconf-set-selections <<< "mysql-server mysql-server/root_password       password ${mysql_root_password}"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${mysql_root_password}"

apt-get update -y
apt-get install -y mysql-server

# ── Konfigurer MySQL for eksterne tilkoblinger ───────────────────────────────
# Oppdaterer bind-address til 0.0.0.0 uansett hvor den er definert
find /etc/mysql/ -name "*.cnf" -type f -exec sed -i 's/^bind-address\s*=.*/bind-address = 0.0.0.0/' {} +

# ── Start MySQL ───────────────────────────────────────────────────────────────
systemctl enable mysql
systemctl restart mysql

# ── Vent til MySQL er klar ────────────────────────────────────────────────────
echo "[$(date)] Venter på at MySQL skal bli klar på port 3306..."
MAX_RETRIES=20
COUNT=0
while ! nc -z localhost 3306; do
  COUNT=$((COUNT + 1))
  if [ $COUNT -ge $MAX_RETRIES ]; then
    echo "[$(date)] FEIL: MySQL startet ikke etter 20 forsøk."
    exit 1
  fi
  sleep 5
done
echo "[$(date)] MySQL er oppe!"

# ── Sikre MySQL og opprett applikasjonsressurser ─────────────────────────────
mysql -u root -p"${mysql_root_password}" << SQLEOF
-- Sikre installasjonen
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;

-- Opprett applikasjonsdatabase
CREATE DATABASE IF NOT EXISTS \`${mysql_database_name}\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

-- Opprett applikasjonsbruker med begrensede rettigheter
CREATE USER IF NOT EXISTS '${mysql_app_user}'@'%'
  IDENTIFIED WITH mysql_native_password BY '${mysql_app_password}';

-- Gi kun nødvendige rettigheter på applikasjonsdatabasen
GRANT SELECT, INSERT, UPDATE, DELETE
  ON \`${mysql_database_name}\`.*
  TO '${mysql_app_user}'@'%';

FLUSH PRIVILEGES;

-- Bytt til applikasjonsdatabasen
USE \`${mysql_database_name}\`;

-- Products-tabell for demo og verifisering
CREATE TABLE IF NOT EXISTS products (
  id         INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  name       VARCHAR(120)     NOT NULL,
  category   VARCHAR(60)      NOT NULL,
  price      DECIMAL(10,2)    NOT NULL,
  stock      INT UNSIGNED     NOT NULL DEFAULT 0,
  served_by  VARCHAR(30)      NOT NULL DEFAULT 'db-vm-${vm_index}',
  created_at TIMESTAMP        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  INDEX idx_category (category)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Legg inn demodata
-- IGNORE hindrer duplikater ved ny kjøring
INSERT IGNORE INTO products (id, name, category, price, stock, served_by) VALUES
  (1,  'Azure Virtual Machine',        'Compute',    120.00, 50,  'db-vm-${vm_index}'),
  (2,  'Azure Blob Storage',           'Storage',     18.50, 100, 'db-vm-${vm_index}'),
  (3,  'Azure Load Balancer',          'Networking',  20.00, 200, 'db-vm-${vm_index}'),
  (4,  'Azure Kubernetes Service',     'Containers', 250.00, 30,  'db-vm-${vm_index}'),
  (5,  'Azure SQL Database',           'Database',    75.00, 80,  'db-vm-${vm_index}'),
  (6,  'Azure Monitor',                'Management',  35.00, 150, 'db-vm-${vm_index}'),
  (7,  'Azure Key Vault',              'Security',    42.00, 90,  'db-vm-${vm_index}'),
  (8,  'Azure Active Directory',       'Identity',    55.00, 75,  'db-vm-${vm_index}'),
  (9,  'Azure Functions',              'Serverless',  15.00, 300, 'db-vm-${vm_index}'),
  (10, 'Azure Application Gateway',    'Networking',  90.00, 40,  'db-vm-${vm_index}');

SQLEOF

echo "[$(date)] MySQL er konfigurert på DB-VM-${vm_index}"
echo "[$(date)] Database: ${mysql_database_name}"
echo "[$(date)] Applikasjonsbruker: ${mysql_app_user}"
echo "[$(date)] MySQL lytter på 0.0.0.0:3306"
echo "[$(date)] Initialisering av DB-server fullført!"