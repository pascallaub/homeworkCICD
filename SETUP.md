# CI/CD Pipeline Setup Anleitung

## Voraussetzungen

### 1. AWS Account und IAM User

Erstellen Sie einen IAM User mit folgenden Berechtigungen:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ec2:*", "vpc:*", "s3:*", "dynamodb:*", "iam:PassRole"],
      "Resource": "*"
    }
  ]
}
```

### 2. AWS CLI Setup

```bash
aws configure
# Geben Sie Access Key ID, Secret Access Key und Region ein
```

## Setup Schritte

### 1. Repository initialisieren

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin <your-github-repo-url>
git push -u origin main
```

### 2. AWS Infrastruktur für Terraform State

```bash
chmod +x scripts/setup-aws.sh
./scripts/setup-aws.sh
```

### 3. GitHub Secrets konfigurieren

Gehen Sie zu GitHub Repository → Settings → Secrets and variables → Actions

Erstellen Sie folgende Secrets:

- `AWS_ACCESS_KEY_ID`: Ihre AWS Access Key ID
- `AWS_SECRET_ACCESS_KEY`: Ihr AWS Secret Access Key
- `AWS_ACCESS_TOKEN`: Session Token (optional, nur bei temporären Credentials)
- `AWS_REGION`: eu-central-1 (oder Ihre bevorzugte Region)
- `TF_STATE_BUCKET`: Name des S3 Buckets aus setup-aws.sh

### 4. Terraform Backend konfigurieren

Aktualisieren Sie `terraform/main.tf` mit dem korrekten Bucket-Namen:

```hcl
backend "s3" {
  bucket         = "ihr-terraform-state-bucket-name"
  key            = "terraform/state"
  region         = "eu-central-1"
  dynamodb_table = "terraform-locks"
  encrypt        = true
}
```

### 5. Pipeline starten

```bash
git add .
git commit -m "Configure pipeline"
git push origin main
```

## Pipeline Überwachung

1. Gehen Sie zu GitHub → Actions
2. Überwachen Sie den Workflow "Deploy React App to AWS EC2"
3. Prüfen Sie die Logs jedes Jobs bei Fehlern

## Verifikation

Nach erfolgreichem Deployment:

1. Prüfen Sie die AWS Console → EC2 → Instances
2. Notieren Sie die öffentliche IP der Instanz
3. Besuchen Sie http://IHRE-EC2-IP im Browser
4. Die React-Anwendung sollte sichtbar sein

## Cleanup

### Automatisches Cleanup via GitHub Actions

1. Gehen Sie zu GitHub → Actions
2. Führen Sie den Workflow "Destroy Infrastructure" aus
3. Geben Sie "destroy" als Bestätigung ein

### Manuelles Cleanup

```bash
export TF_STATE_BUCKET="ihr-bucket-name"
./scripts/cleanup-aws.sh
```

## Troubleshooting

### Häufige Probleme:

1. **Terraform Backend Error**: Prüfen Sie Bucket-Name und Permissions
2. **SSH Connection Failed**: EC2 Instance benötigt Zeit zum Starten (bis zu 5 Minuten)
3. **Build Fails**: Prüfen Sie Node.js Version und Dependencies
4. **Permission Denied**: Prüfen Sie IAM User Berechtigungen

### Logs prüfen:

```bash
# GitHub Actions Logs online verfügbar
# EC2 Instance Logs via SSH:
ssh -i ssh_key.pem ubuntu@INSTANCE-IP
sudo journalctl -u nginx
sudo cat /var/log/user-data.log
```

## Best Practices

1. **Secrets Management**: Niemals Credentials in Code committen
2. **State Locking**: DynamoDB verhindert Race Conditions
3. **Resource Tagging**: Alle Resources sind mit Project/Environment getaggt
4. **Health Checks**: Pipeline führt automatische Gesundheitsprüfungen durch
5. **Rollback**: Bei Fehlern Destroy-Workflow verwenden

## Weiterentwicklung

Mögliche Erweiterungen:

- HTTPS mit Let's Encrypt
- Auto Scaling Groups
- Load Balancer
- CloudWatch Monitoring
- Blue/Green Deployments
