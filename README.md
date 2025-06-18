# React CI/CD Application

Eine moderne React-Anwendung mit vollautomatisierter CI/CD-Pipeline über GitHub Actions, Terraform und AWS EC2.

## Funktionen

- **React 18** mit Vite als Build-Tool
- **Automatisierte CI/CD-Pipeline** mit GitHub Actions
- **Infrastructure as Code** mit Terraform
- **AWS EC2 Deployment** mit Nginx
- **Automatisierte Tests** und Build-Validierung

## Architektur

- **Frontend**: React 18 mit Vite
- **Infrastructure**: AWS VPC, EC2, Security Groups
- **Web Server**: Nginx auf Ubuntu 22.04 LTS
- **CI/CD**: GitHub Actions mit Multi-Stage Pipeline

## Lokale Entwicklung

```bash
npm install
npm run dev
npm run build
npm test
```

## Deployment

Die Anwendung wird automatisch über GitHub Actions deployt bei Push auf den `main` Branch.

### Pipeline Stages:

1. **Build & Test**: Code Checkout, Dependency Installation, Testing, Build
2. **Infrastructure Provision**: Terraform Apply für AWS Resources
3. **Application Deploy**: SCP Upload und Nginx Configuration

## AWS Resources

- VPC mit öffentlichem Subnet
- EC2 Instance (t3.micro)
- Security Groups für HTTP/HTTPS und SSH
- Auto-generiertes SSH Key Pair
- Internet Gateway und Route Tables
