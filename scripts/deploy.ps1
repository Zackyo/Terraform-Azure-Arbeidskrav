# =============================================================================
# deploy.ps1 — Ett-klikk utrullingsskript (Windows PowerShell)
# =============================================================================

param (
    [string]$Action = "apply",
    [string]$VarFile = "terraform.tfvars"
)

# ── Sett arbeidskatalog ───────────────────────────────────────────────────────
# Skriptet ligger i 'scripts'-mappen
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location "$ScriptDir\.."
Write-Host "Arbeidskatalog: $(Get-Location)"

# ── Farger ────────────────────────────────────────────────────────────────────
$Green = "Green"
$Yellow = "Yellow"
$Red = "Red"
$Cyan = "Cyan"
$Gray = "Gray"

Write-Host ""
Write-Host "==========================================================" -ForegroundColor $Cyan
Write-Host "  Azure Web-DB Terraform utrulling" -ForegroundColor $Cyan
Write-Host "  Handling: $Action" -ForegroundColor $Yellow
Write-Host "==========================================================" -ForegroundColor $Cyan
Write-Host ""

# ── Forutsetninger ────────────────────────────────────────────────────────────
foreach ($cmd in @("terraform", "az")) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host "[FEIL] '$cmd' er ikke installert." -ForegroundColor $Red
        exit 1
    }
}

# ── Azure innlogging ─────────────────────────────────────────────────────────
Write-Host "[1/5] Sjekker Azure-innlogging..." -ForegroundColor $Green

try {
    az account show | Out-Null
} catch {
    Write-Host "Ikke innlogget. Kjører 'az login'..."
    az login
}

az account show --query "{Navn:name,Id:id}" -o table

# ── Init ──────────────────────────────────────────────────────────────────────
Write-Host "[2/5] Terraform init..." -ForegroundColor $Green
terraform init -upgrade

# ── Validering ───────────────────────────────────────────────────────────────
Write-Host "[3/5] Validerer konfigurasjon..." -ForegroundColor $Green
terraform validate
Write-Host "Konfigurasjonen er gyldig!" -ForegroundColor $Gray

# ── Plan ──────────────────────────────────────────────────────────────────────
Write-Host "[4/5] Genererer plan..." -ForegroundColor $Green
terraform plan -var-file="$VarFile" -out=tfplan.binary

if ($Action -eq "plan") {
    Write-Host "Plan ferdig. Kjør med 'apply' for å deploye." -ForegroundColor $Yellow
    exit 0
}

# ── Apply / Destroy ───────────────────────────────────────────────────────────
Write-Host "[5/5] Kjører Terraform $Action..." -ForegroundColor $Green

if ($Action -eq "destroy") {
    terraform destroy -var-file="$VarFile"
} else {
    terraform apply tfplan.binary
}

# ── Output ────────────────────────────────────────────────────────────────────
if ($Action -eq "apply") {
    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor $Green
    Write-Host "  Utrulling fullført!" -ForegroundColor $Green
    Write-Host "==========================================================" -ForegroundColor $Green

    terraform output

    try {
        $WebIP = terraform output -raw web_vm_public_ip
        if ($WebIP) {
            Write-Host ""
            Write-Host "Web-applikasjon: http://$WebIP" -ForegroundColor $Cyan
            Write-Host "MERK: Vent 3–5 minutter til cloud-init er ferdig." -ForegroundColor $Yellow
        }
    } catch {}

    Write-Host "==========================================================" -ForegroundColor $Green
}

Remove-Item tfplan.binary -ErrorAction SilentlyContinue
Write-Host "Ferdig!" -ForegroundColor $Green