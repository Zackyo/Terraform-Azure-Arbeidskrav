#!/bin/bash
# =============================================================================
# deploy.sh — Ett-klikk utrullingsskript (Linux / macOS / WSL / Git Bash)
# =============================================================================

set -euo pipefail

# ── Sett arbeidskatalog ───────────────────────────────────────────────────────
# Skriptet ligger i 'scripts'-mappen
# Terraform må kjøres fra prosjektroten (ett nivå opp)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/.."
echo "Arbeidskatalog: $(pwd)"

ACTION="${1:-apply}"
VAR_FILE="${2:-terraform.tfvars}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[0;37m'; NC='\033[0m'

echo ""
echo -e "${CYAN}==========================================================${NC}"
echo -e "${CYAN}  Azure Web-DB Terraform utrulling${NC}"
echo -e "${YELLOW}  Handling: $ACTION${NC}"
echo -e "${CYAN}==========================================================${NC}"
echo ""

# ── Forutsetninger ────────────────────────────────────────────────────────────
for cmd in terraform az; do
  if ! command -v "$cmd" &>/dev/null; then
    echo -e "${RED}[FEIL] '$cmd' er ikke installert.${NC}"
    exit 1
  fi
done

# ── Azure-innlogging ──────────────────────────────────────────────────────────
echo -e "${GREEN}[1/5] Sjekker Azure-innlogging...${NC}"
if ! az account show &>/dev/null; then
  echo "      Ikke innlogget. Kjører 'az login'..."
  az login
fi
az account show --query "{Navn:name,Id:id}" -o table

# ── Init ──────────────────────────────────────────────────────────────────────
echo -e "${GREEN}[2/5] Terraform init...${NC}"
terraform init -upgrade

# ── Validering ───────────────────────────────────────────────────────────────
echo -e "${GREEN}[3/5] Validerer konfigurasjon...${NC}"
terraform validate
echo -e "${GRAY}      Konfigurasjonen er gyldig!${NC}"

# ── Plan ──────────────────────────────────────────────────────────────────────
echo -e "${GREEN}[4/5] Genererer plan...${NC}"
terraform plan -var-file="$VAR_FILE" -out=tfplan.binary

if [[ "$ACTION" == "plan" ]]; then
  echo -e "${YELLOW}Plan ferdig. Kjør med 'apply' for utrulling.${NC}"
  exit 0
fi

# ── Apply / Destroy ───────────────────────────────────────────────────────────
echo -e "${GREEN}[5/5] Kjører Terraform $ACTION...${NC}"

if [[ "$ACTION" == "destroy" ]]; then
  terraform destroy -var-file="$VAR_FILE"
else
  terraform apply tfplan.binary
fi

# ── Output ────────────────────────────────────────────────────────────────────
if [[ "$ACTION" == "apply" ]]; then
  echo ""
  echo -e "${GREEN}==========================================================${NC}"
  echo -e "${GREEN}  Utrulling fullført!${NC}"
  echo -e "${GREEN}==========================================================${NC}"

  terraform output

  WEB_IP=$(terraform output -raw web_vm_public_ip 2>/dev/null || true)

  if [[ -n "$WEB_IP" ]]; then
    echo ""
    echo -e "${CYAN}  Webapplikasjon: http://$WEB_IP${NC}"
    echo -e "${YELLOW}  MERK: Vent 3–5 minutter til cloud-init er ferdig.${NC}"
  fi

  echo -e "${GREEN}==========================================================${NC}"
fi

rm -f tfplan.binary
echo -e "${GREEN}Ferdig!${NC}"