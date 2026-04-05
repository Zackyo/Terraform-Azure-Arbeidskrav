# Azure Web-DB Infrastruktur — Terraform-prosjekt

> Terraform-basert Azure-infrastruktur.
Et fullautomatisert miljø med webapplikasjon og lastbalanserte MySQL-databaser, deployet via modulbasert Terraform.

📖 Se SETUP-GUIDE.md for komplett steg-for-steg oppsett og verifisering.

---

## Arkitektur

Internet → Web VM (Public IP) → Internal Load Balancer → DB VM 1 / DB VM 2

### Hovedprinsipper
- Segmentert nettverk (web + db subnett)
- Ingen offentlig tilgang til databaser
- Lastbalansering av MySQL
- Automatisert oppsett (cloud-init)
- Minst mulig tilgang (least privilege)

---

## Struktur

project/
- main.tf
- globals.tf
- outputs.tf
- backend.tf
- terraform.tfvars
- scripts/
- modules/

Moduler:
- networking
- security
- load-balancer
- compute

---

## Rask oppstart

git clone https://github.com/<your-username>/azure-webdb-terraform.git
cd azure-webdb-terraform/project

cp terraform.tfvars.example terraform.tfvars

Oppdater passord i terraform.tfvars

az login
terraform apply -var-file="terraform.tfvars"

---

## Tilgang

terraform output web_vm_public_ip

Åpne:
http://<IP>

Vent 3–5 minutter etter deploy.

---

## Sikkerhet

- DB har ingen public IP
- Kun web subnet har tilgang
- NSG blokkerer øvrig trafikk
- SSH via web VM

---

## Ressurser

- 1 Resource Group
- 1 VNet
- 2 Subnets
- 3 VM-er
- 1 Load Balancer

---

## Kostnad

~100–120 USD/mnd

---

## Slett

terraform destroy -var-file="terraform.tfvars"

---

## Lisens

MIT
