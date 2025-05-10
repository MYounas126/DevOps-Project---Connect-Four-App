# 🚀 DevSecOps Connect Four Deployment

![CI/CD](https://img.shields.io/badge/Jenkins-CI%2FCD-blue)
![Docker](https://img.shields.io/badge/Docker-Containerized-blue)
![Kubernetes](https://img.shields.io/badge/K8s-Deployed-green)
![Security](https://img.shields.io/badge/Security-Scanned-critical)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

> A full-stack DevSecOps project demonstrating secure deployment of a containerized Connect Four game using Docker, Terraform, Jenkins, and Kubernetes on AWS EKS.

---

## 📌 Table of Contents

- [🎯 Project Overview](#-project-overview)
- [🧠 Features](#-features)
- [🧰 Tech Stack](#-tech-stack)
- [📁 Folder Structure](#-folder-structure)
- [⚙️ How to Run](#️-how-to-run)
- [🔐 Security Integration](#-security-integration)
- [📊 Monitoring](#-monitoring)
- [📌 Future Improvements](#-future-improvements)
- [📜 License](#-license)

---

## 🎯 Project Overview

This project implements a complete **DevSecOps pipeline** for deploying a static **Connect Four game** built with HTML, CSS, and JavaScript. It automates the entire process from code push to deployment, while integrating **security scanning**, **infrastructure as code**, and **monitoring** into a single workflow.

---

## 🧠 Features

- 🔄 **CI/CD Pipeline** with Jenkins
- 🐳 **Dockerized** frontend application
- ☁️ **AWS EKS provisioning** with Terraform
- 🔐 Security Scans: Trivy, OWASP ZAP, KubeAudit
- 🧠 Real-time **monitoring** via Prometheus & Grafana
- 📬 **Email notifications** for pipeline status and alerts

---

## 🧰 Tech Stack

| Category        | Technology          |
|----------------|---------------------|
| Frontend       | HTML, CSS, JavaScript |
| CI/CD          | Jenkins             |
| Containerization | Docker            |
| Infrastructure | Terraform + AWS EKS |
| Orchestration  | Kubernetes          |
| Security       | Trivy, OWASP ZAP, KubeAudit |
| Monitoring     | Prometheus, Grafana |
| Notifications  | Gmail (SMTP alerts) |

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
