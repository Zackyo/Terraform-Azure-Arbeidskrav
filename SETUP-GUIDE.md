# Oppsettguide — Azure Web-DB Terraform-prosjekt

## 1. Forutsetninger

- Terraform
- Azure CLI
- Git
- Aktiv Azure Subscription

---

## 2. Klon prosjekt

git clone https://github.com/<brukernavn>/azure-webdb-terraform.git
cd azure-webdb-terraform/project

---

## 3. Konfigurer variabler

cp terraform.tfvars.example terraform.tfvars

Oppdater:
- admin_password
- mysql_root_password
- mysql_app_password

---

## 4. Azure login

az login
az account set --subscription "<subscription-id>"

---

## 5. Deploy

./scripts/deploy.sh apply

eller:

terraform init
terraform apply -var-file="terraform.tfvars"

---

## 6. Verifisering

Web:
terraform output web_vm_public_ip
Åpne http://< IP >

API:
curl http://< IP >/api/health

Database:
ssh azureuser@< IP >
mysql -h <LB_IP> -u appuser -p

SELECT * FROM products;

---

## 7. Feilsøking

Web:
systemctl status webapp

DB:
systemctl status mysql

---

## 8. Slett

terraform destroy -var-file="terraform.tfvars"
