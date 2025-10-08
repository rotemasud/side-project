# Side Project - Cloud-Native Spring Boot Application

A comprehensive cloud-native Spring Boot application deployed on AWS EKS with modern DevOps practices including Infrastructure as Code, GitOps, and observability.

## 🏗️ Architecture Overview

This project demonstrates a complete cloud-native application stack:

- **Application**: Spring Boot 3.3.1 with Java 17
- **Infrastructure**: AWS EKS cluster with Terraform
- **Container Orchestration**: Kubernetes with Helm charts
- **GitOps**: ArgoCD for continuous deployment
- **Service Mesh**: Istio (optional)
- **Auto-scaling**: Karpenter for node provisioning
- **Observability**: Prometheus metrics and monitoring
- **Storage**: EBS CSI driver for persistent volumes

## 🚀 Features

- **Spring Boot Web Application**: RESTful API with health checks and metrics
- **Containerized**: Multi-stage Docker build with security best practices
- **Kubernetes Ready**: Complete Helm chart with HPA, service mesh, and ingress
- **Infrastructure as Code**: Terraform modules for AWS resources
- **GitOps Workflow**: ArgoCD for automated deployments
- **Auto-scaling**: Horizontal Pod Autoscaler and Karpenter node provisioning
- **Monitoring**: Prometheus metrics exposure and health endpoints
- **Security**: Non-root container user and proper RBAC

```

## 🛡️ Security Features

- **Non-root container**: Application runs as user 1000
- **RBAC**: Proper Kubernetes service accounts
- **Network policies**: Istio security policies (when enabled)
- **Resource limits**: CPU and memory constraints
- **Pod security**: Security contexts configured


### Karpenter Node Provisioning

- Automatic node scaling based on pod requirements
- Cost optimization with spot instances
- Multi-AZ deployment for high availability

## 📄 License

This project is licensed under the terms specified in the LICENSE.txt file.

---
