````markdown
# CI/CD-Pipeline für React + Terraform + AWS EC2 mit GitHub Actions

## 🧩 Projektbeschreibung

Dieses Projekt zeigt eine vollständige CI/CD-Pipeline zur Bereitstellung einer React-App auf einer AWS EC2 Instanz mit Terraform und GitHub Actions.

---

## 🚀 Setupanleitung

1. React-App mit Vite erstellen:
   ```bash
   npm create vite@latest
````

2. SSH-Key erzeugen:

   ```bash
   ssh-keygen -t rsa -b 4096
   ```

3. GitHub-Secrets einrichten:

   * `AWS_ACCESS_KEY_ID`
   * `AWS_SECRET_ACCESS_KEY`
   * `AWS_REGION`
   * `TF_STATE_BUCKET`
   * `SSH_PRIVATE_KEY`

4. S3-Bucket und DynamoDB-Tabelle in AWS **manuell** anlegen.

5. Terraform konfigurieren und Workflow-Dateien (`.github/workflows/`) erstellen.

6. Code auf `main` pushen.

---

## 🔐 GitHub Secrets Übersicht

*(Keine echten Werte eintragen!)*

| Secret Name             | Zweck                                     |
| ----------------------- | ----------------------------------------- |
| `AWS_ACCESS_KEY_ID`     | Zugriff auf AWS                           |
| `AWS_SECRET_ACCESS_KEY` | Zugriff auf AWS                           |
| `AWS_REGION`            | z. B. `eu-central-1`                      |
| `TF_STATE_BUCKET`       | S3-Bucket für Terraform-State             |
| `SSH_PRIVATE_KEY`       | Privater Schlüssel für SSH-Zugang zur EC2 |

---

## ⚙️ Ausführung der Pipeline

* Push auf den `main`-Branch:

  * Startet CI-Build
  * Führt Terraform `apply` aus
  * Deployt die App auf EC2
* `destroy-infra.yml`:

  * Kann manuell über die GitHub Actions UI ausgelöst werden
  * Führt `terraform destroy` aus

---

## 💭 Reflektionsfragen und Antworten

### 1. Welche Rolle hat jeder Job in der Pipeline?

* **`ci_build`**: Baut und testet die React App, speichert das Artefakt.
* **`infra_provision`**: Stellt mit Terraform die Infrastruktur bereit.
* **`app_deploy`**: Holt das Artefakt, kopiert es per SSH auf die EC2 Instanz und startet Nginx.

---

### 2. Wie wurde das Artefakt übergeben?

Mit `actions/upload-artifact` im CI-Job und `actions/download-artifact` im Deploy-Job.

---

### 3. Wie wurden sensible Daten gespeichert und verwendet?

Sicher als GitHub Secrets. In Workflows durch `${{ secrets.NAME }}` eingebunden – deutlich sicherer als im Code oder in Umgebungsdateien.

---

### 4. Wie wurde die EC2-IP ermittelt?

Durch Terraform Output:

```bash
terraform output -raw ec2_ip
```

→ in eine Umgebungsvariable gespeichert und im nächsten Job verwendet.

---

### 5. Was passiert bei erneutem Push?

* Terraform erkennt keine Änderung → Infrastruktur bleibt bestehen.
* Das Deployment kann dennoch erfolgen, z. B. wenn sich der Frontend-Code geändert hat.

---

### 6. Welche Schritte machen die neue App-Version sichtbar?

* `scp` kopiert das `dist/`-Verzeichnis auf die EC2-Instanz nach `/var/www/html`.
* `ssh` führt `sudo systemctl restart nginx` aus → App wird sofort neu geladen.

---
