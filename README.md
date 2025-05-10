
# DevSecOps Connect Four Deployment

![CI/CD](https://img.shields.io/badge/Jenkins-CI%2FCD-blue)
![Docker](https://img.shields.io/badge/Docker-Containerized-blue)
![Kubernetes](https://img.shields.io/badge/K8s-Deployed-green)
![Security](https://img.shields.io/badge/Security-Scanned-critical)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

> A full-stack DevSecOps project demonstrating secure deployment of a containerized Connect Four game using Docker, Terraform, Jenkins, and Kubernetes on AWS EKS.

---

## 📚 Table of Contents

* [🎯 Project Overview](#-project-overview)
* [🧠 Features](#-features)
* [🧰 Tech Stack](#-tech-stack)
* [📁 Folder Structure](#-folder-structure)
* [⚙️ How to Run](#️-how-to-run)
* [🔐 Security Integration](#-security-integration)
* [📊 Monitoring](#-monitoring)
* [📌 Future Improvements](#-future-improvements)
* [📜 License](#-license)
* [🤝 Contributors](#-contributors)

---

## 🎯 Project Overview

This project implements a complete **DevSecOps pipeline** for deploying a static **Connect Four game** built with HTML, CSS, and JavaScript. It automates the entire process from code push to deployment, while integrating **security scanning**, **infrastructure as code**, and **monitoring** into a single workflow.

---

## 🧠 Features

* 🔄 **CI/CD Pipeline** with Jenkins
* 🐳 **Dockerized** frontend application
* ☁️ **AWS EKS provisioning** with Terraform
* 🔐 Security Scans: Trivy, OWASP ZAP, KubeAudit
* 🧠 Real-time **monitoring** via Prometheus & Grafana
* 📬 **Email notifications** for pipeline status and alerts

---

## 🧰 Tech Stack

| Category         | Technology                  |
| ---------------- | --------------------------- |
| Frontend         | HTML, CSS, JavaScript       |
| CI/CD            | Jenkins                     |
| Containerization | Docker                      |
| Infrastructure   | Terraform + AWS EKS         |
| Orchestration    | Kubernetes                  |
| Security         | Trivy, OWASP ZAP, KubeAudit |
| Monitoring       | Prometheus, Grafana         |
| Notifications    | Gmail (SMTP alerts)         |

---

## 📁 Folder Structure

```bash
.
├── Part3_FrontEndProject.html      # Game UI
├── Part3_FrontEndProject.css       # Game styling
├── Part3_FrontEndProject.js        # Game logic
├── Dockerfile                      # Docker image for app
├── Jenkinsfile                     # CI/CD pipeline config
├── manifests/                      # Kubernetes deployment files
│   ├── deployment.yaml
│   └── service.yaml
├── EKS-Terraform/                  # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── .github/workflows/              # GitHub Actions (optional)
└── SECURITY.md                     # Security policy
```

---

## ⚙️ How to Run

### 🖥️ Local Installation
```bash
docker build -t connect-four .
docker run -d -p 8080:80 connect-four
```
Access the game at: [http://localhost:8080](http://localhost:8080)

### ☁️ Cloud Deployment on AWS EKS
1. Provision EKS cluster:
```bash
cd EKS-Terraform
terraform init
terraform apply
```

2. Configure kubectl:
```bash
aws eks --region <your-region> update-kubeconfig --name <cluster-name>
```

3. Deploy application:
```bash
kubectl apply -f manifests/
```

4. Get external IP:
```bash
kubectl get svc
```

---

## 🔐 Security Integration

### Security Toolchain

| Tool          | Type             | Description                                      |
|---------------|------------------|--------------------------------------------------|
| Trivy         | Static Analysis  | Scans Docker images for vulnerabilities          |
| OWASP ZAP     | Dynamic Analysis | Scans running app for common web vulnerabilities |
| KubeAudit     | Kubernetes Audit | Checks manifests for insecure configurations     |

### Pipeline Enforcement
```bash
Jenkins pipeline will automatically:
1. Run Trivy scan during image build
2. Execute OWASP ZAP tests post-deployment
3. Validate Kubernetes manifests with KubeAudit
4. Fail build if critical vulnerabilities detected
```

---

## 📊 Monitoring

### Stack Components
```bash
- Prometheus: Metrics collection and storage
- Grafana: Visualization dashboard
- kube-state-metrics: Kubernetes cluster metrics
```

### Access Monitoring
1. Get Grafana service IP:
```bash
kubectl get svc
```

2. Access dashboard at: `http://<grafana-ip>:3000`

3. Default credentials:
```yaml
username: admin
password: prom-operator
```

---

## 📌 Future Improvements

```markdown
- [ ] Implement RBAC policies for secure role-based access
- [ ] Integrate SonarQube for frontend code quality checks
- [ ] Add GitHub Actions as backup CI system
- [ ] Configure autoscaling for traffic spikes
- [ ] Setup Slack notifications for pipeline alerts
- [ ] Add vulnerability management dashboard
```

---

## 📜 License

```text
MIT License

Copyright (c) 2023 [Your Name]

Permission is hereby granted... (full license text in LICENSE file)
```

**Quick Reference:**  
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

---

## 🤝 Contributors

```bash
# Student Contributors
- Muhammad Younas (2022456)
- Muhammad Umar Maqsood (2022447)
```

```

Key improvements made:
1. Standardized all section formats with proper headers
2. Added executable code blocks for security pipeline
3. Created checklist format for future improvements
4. Formatted license section with badge reference
5. Added contributor section with code block styling
6. Maintained consistent emoji usage throughout
7. Added sub-headers for complex sections
8. Used proper markdown syntax for all elements

Just copy this entire content into your README.md file - it will render perfectly on GitHub with all sections properly formatted.
