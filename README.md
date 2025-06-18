````markdown
# CI/CD Pipeline für Web-Anwendung mit AWS EC2

Dieses Projekt implementiert eine vollständige CI/CD-Pipeline, die eine Web-Anwendung automatisch auf AWS EC2 (Ubuntu) deployed.

## Projektübersicht

Die Pipeline führt folgende Schritte aus:
1. **CI Build**: Baut die Anwendung und erstellt Artifacts
2. **Infrastructure Provision**: Erstellt AWS-Infrastruktur mit Terraform
3. **Application Deploy**: Deployed die Anwendung auf EC2

## Architektur

- **Frontend**: Node.js Anwendung
- **Server**: Ubuntu 22.04 LTS EC2 Instance
- **Webserver**: Nginx
- **Infrastructure as Code**: Terraform
- **CI/CD**: GitHub Actions
- **Cloud Provider**: AWS

## Projekt-Struktur

```
homeworkCICD/
├── .github/
│   └── workflows/
│       ├── deploy.yml          # Haupt-Deployment Pipeline
│       └── destroy.yml         # Infrastructure Destroy Pipeline
├── terraform/
│   ├── main.tf                 # EC2, Security Groups, SSH Keys
│   ├── provider.tf             # AWS Provider Konfiguration
│   ├── variables.tf            # Terraform Variablen
│   ├── outputs.tf              # Terraform Outputs
│   ├── backend.tf              # S3 Backend Konfiguration
│   └── terraform.tfvars        # Variable Werte
├── src/                        # Anwendungs-Quellcode
├── dist/                       # Build-Artifacts (generiert)
├── package.json                # Node.js Dependencies
└── README.md
```

## Setup & Deployment

### 1. AWS-Vorbereitung

Erstellen Sie manuell folgende AWS-Ressourcen:

```bash
# S3 Bucket für Terraform State
aws s3 mb s3://ihr-terraform-state-bucket-name --region eu-central-1

# DynamoDB Tabelle für State Locking
aws dynamodb create-table \
    --table-name ihr-terraform-locks \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region eu-central-1
```

### 2. GitHub Secrets konfigurieren

Fügen Sie folgende Secrets in Ihrem GitHub Repository hinzu:
- `AWS_ACCESS_KEY_ID`: Ihr AWS Access Key
- `AWS_SECRET_ACCESS_KEY`: Ihr AWS Secret Key
- `AWS_REGION`: `eu-central-1` (oder Ihre bevorzugte Region)
- `TF_STATE_BUCKET`: Name Ihres S3-Buckets für Terraform State

### 3. Terraform-Konfiguration anpassen

Bearbeiten Sie `terraform/terraform.tfvars`:
```hcl
aws_region = "eu-central-1"
tf_state_bucket = "ihr-terraform-state-bucket-name"
instance_type = "t2.micro"
```

Bearbeiten Sie `terraform/backend.tf`:
```hcl
terraform {
  backend "s3" {
    bucket         = "ihr-terraform-state-bucket-name"
    key            = "terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "ihr-terraform-locks"
    encrypt        = true
  }
}
```

### 4. Deployment starten

Push Ihre Änderungen in den `main` Branch:
```bash
git add .
git commit -m "Initial deployment setup"
git push origin main
```

Die Pipeline startet automatisch und:
- Baut die Anwendung
- Erstellt EC2-Infrastruktur
- Deployed die Anwendung

## Pipeline-Details

### CI Build Job
- Checkout des Codes
- Node.js Setup (Version 18)
- Dependencies installieren (`npm install`)
- Anwendung bauen (`npm run build`)
- Build-Artifacts hochladen

### Infrastructure Provision Job
- Terraform Setup
- AWS Credentials konfigurieren
- SSH-Schlüssel automatisch generieren
- EC2-Instance mit Ubuntu 22.04 LTS erstellen
- Security Groups für HTTP/HTTPS/SSH
- Nginx automatisch installieren und konfigurieren

### Application Deploy Job
- Build-Artifacts herunterladen
- SSH-Verbindung zur EC2-Instance
- Anwendung in `/var/www/html/` deployen
- Nginx neustarten
- Deployment verifizieren

## Sicherheitsfeatures

- **Automatische SSH-Schlüssel**: Werden pro Deployment generiert
- **Security Groups**: Nur notwendige Ports geöffnet
- **Encrypted Terraform State**: In S3 mit Verschlüsselung
- **State Locking**: Verhindert parallele Terraform-Ausführungen
- **Minimal IAM**: Nur notwendige AWS-Berechtigungen

## Infrastructure Cleanup

Zur Zerstörung der Infrastruktur:
1. Gehen Sie zu "Actions" in GitHub
2. Wählen Sie "Destroy Infrastructure"
3. Klicken Sie "Run workflow"

Oder manuell:
```bash
cd terraform
terraform destroy
```

## Monitoring & Logs

- **EC2-Instance**: Über AWS Console überwachen
- **Nginx-Logs**: `/var/log/nginx/` auf der EC2-Instance
- **Pipeline-Logs**: GitHub Actions Tab
- **Application**: Erreichbar über EC2 Public IP

## Troubleshooting

### Häufige Probleme:

1. **"Parameter not found"**: AWS IAM-Berechtigungen prüfen
2. **SSH-Verbindung fehlgeschlagen**: Security Groups prüfen
3. **Nginx startet nicht**: User Data Logs in EC2 prüfen
4. **Terraform State Lock**: DynamoDB-Tabelle prüfen

### Debug-Befehle:

```bash
# SSH zur EC2-Instance
ssh -i ~/.ssh/id_rsa ubuntu@<EC2-IP>

# Nginx Status prüfen
sudo systemctl status nginx

# Nginx Logs
sudo tail -f /var/log/nginx/error.log

# User Data Logs
sudo cat /var/log/cloud-init-output.log
```

## Nächste Schritte

- [ ] SSL/TLS Zertifikate hinzufügen
- [ ] Load Balancer implementieren
- [ ] Auto Scaling Groups
- [ ] CloudWatch Monitoring
- [ ] Blue/Green Deployments
- [ ] Database Integration

## Technische Details

- **EC2 Instance**: t2.micro (Free Tier eligible)
- **Operating System**: Ubuntu 22.04 LTS
- **Webserver**: Nginx
- **Node.js Version**: 22
- **Terraform Provider**: AWS ~> 5.0
- **GitHub Actions**: ubuntu-latest runners



## Reflexionsfragen


### 1. Rolle der Jobs und Abhängigkeiten

**ci_build Job:**
- **Rolle**: Kompiliert den Quellcode, installiert Dependencies und erstellt das Build-Artefakt
- **Zweck**: Stellt sicher, dass der Code funktionsfähig ist und ein deployable Artefakt erzeugt wird
- **Abhängigkeiten**: Keine (startet als erstes)

**infra_provision Job:**
- **Rolle**: Erstellt und konfiguriert die AWS-Infrastruktur mit Terraform
- **Zweck**: Stellt EC2-Instance, Security Groups und SSH-Keys bereit
- **Abhängigkeiten**: `needs: ci_build` - startet erst nach erfolgreichem Build

**app_deploy Job:**
- **Rolle**: Deployed das Build-Artefakt auf die bereitgestellte Infrastruktur
- **Zweck**: Kopiert die Anwendung auf den Server und startet den Webserver
- **Abhängigkeiten**: `needs: [ci_build, infra_provision]` - startet erst nach beiden vorherigen Jobs

Die `needs`-Konfiguration stellt sicher, dass Jobs nur starten, wenn ihre Abhängigkeiten erfolgreich abgeschlossen wurden. Dies verhindert, dass versucht wird, auf nicht existierende Infrastruktur zu deployen oder fehlerhafte Builds zu verwenden.

### 2. Artefakt-Übergabe zwischen Jobs

**Upload im ci_build Job:**
```yaml
- name: Upload build artifact
  uses: actions/upload-artifact@v4
  with:
    name: dist-files
    path: dist/
```

**Download im app_deploy Job:**
```yaml
- name: Download build artifact
  uses: actions/download-artifact@v4
  with:
    name: dist-files
    path: dist/
```

**Warum notwendig:** GitHub Actions Jobs laufen in isolierten Umgebungen. Ohne Artefakt-Übertragung hätte der Deployment-Job keinen Zugriff auf die kompilierten Dateien. Die Artefakte werden temporär in GitHub gespeichert und können zwischen Jobs geteilt werden.

### 3. Sichere Handhabung sensibler Daten

**AWS Credentials:**
- Gespeichert als GitHub Repository Secrets (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)
- Zugriff über `${{ secrets.VARIABLE_NAME }}`
- Werden automatisch maskiert in Logs

**SSH Private Key:**
- Automatisch von Terraform generiert via `tls_private_key` Resource
- Übertragen als GitHub Actions Artefakt zwischen Jobs
- Nur temporär verfügbar während Pipeline-Ausführung

**Warum sicherer:**
- **Secrets**: Verschlüsselt gespeichert, nur zur Laufzeit verfügbar, nicht im Code sichtbar
- **Automatische Keys**: Werden pro Deployment neu generiert, kein statisches Sicherheitsrisiko
- **Maskierung**: Sensible Daten werden in Logs automatisch verborgen
- **Isolation**: Jeder Job läuft in separater Umgebung

### 4. EC2 IP-Ermittlung und Deployment

**IP-Ermittlung:**
```yaml
- name: Get outputs and save SSH key
  id: terraform_outputs
  run: |
    echo "ip=$(terraform output -raw ec2_ip)" >> $GITHUB_OUTPUT
```

**Übertragung zwischen Jobs:**
```yaml
outputs:
  ec2_ip: ${{ steps.terraform_outputs.outputs.ip }}
```

**Verwendung im Deployment:**
```yaml
needs: [ci_build, infra_provision]
# ...
scp -r dist/* ubuntu@${{ needs.infra_provision.outputs.ec2_ip }}:/tmp/
```

**Prozess:** Terraform gibt die öffentliche IP als Output zurück → wird als Job-Output gesetzt → nachfolgender Job kann darauf zugreifen → SCP und SSH verwenden diese IP für Verbindung.

### 5. Verhalten bei Code-Änderungen

**Was passiert:**
- Terraform führt `terraform plan` aus und erkennt, dass die Infrastruktur bereits existiert
- Keine Änderungen an EC2-Instance, Security Groups oder SSH-Keys
- Terraform zeigt "No changes" an und überspringt Infrastructure-Änderungen
- Nur das `app_deploy` Job deployed die neue Code-Version

**Terraform State:**
- Der State wird in S3 gespeichert und zeigt den aktuellen Zustand
- Terraform vergleicht gewünschten Zustand (Code) mit aktuellem Zustand (AWS)
- Da sich Infrastructure-Code nicht änderte, bleibt die EC2-Instance unverändert

**Effizienz:** Dies ist gewünscht - Infrastructure bleibt stabil, nur Anwendungscode wird aktualisiert.

### 6. Deployment-Schritte für neue App-Version

**Schritte im app_deploy Job:**

1. **Artefakt-Download:** Neue Build-Dateien werden heruntergeladen
2. **SSH-Setup:** Verbindung zur EC2-Instance wird aufgebaut
3. **Datei-Upload:** `scp` kopiert neue Dateien nach `/tmp/` auf dem Server
4. **Alte Version entfernen:** `sudo rm -rf /var/www/html/*` löscht alte Dateien
5. **Neue Version installieren:** `sudo cp -r /tmp/* /var/www/html/` kopiert neue Dateien
6. **Berechtigungen setzen:** `sudo chown -R www-data:www-data /var/www/html`
7. **Webserver neustarten:** `sudo systemctl restart nginx` lädt neue Konfiguration

**Warum Neustart notwendig:** Nginx cached statische Dateien. Der Neustart stellt sicher, dass die neuen Dateien sofort verfügbar sind und alle Verbindungen die neue Version erhalten.

**Sichtbarkeit:** Nach dem Nginx-Neustart ist die neue Version sofort unter der EC2-IP verfügbar.
````

