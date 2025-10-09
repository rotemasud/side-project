# Side Project - Cloud-Native Spring Boot Application

A comprehensive cloud-native Spring Boot application deployed on AWS EKS with modern DevOps practices including Infrastructure as Code, GitOps, and observability.

## 🏗️ Infrastructure & Platform

- **Compute**: AWS EKS (Elastic Kubernetes Service)
- **Infrastructure as Code**: Terraform with modular architecture
- **Container Orchestration**: Kubernetes with Helm charts
- **GitOps**: ArgoCD for continuous deployment
- **Progressive Delivery**: Argo Rollouts (Canary & Blue-Green strategies)
- **Auto-scaling**: Karpenter for intelligent node provisioning
- **Service Mesh**: Istio for traffic management
- **Observability**: Prometheus metrics and monitoring
- **Storage**: AWS EBS CSI driver for persistent volumes

## 🚀 Application Features

- **REST API**: Spring Boot 3.3.1 web application with Java 17
- **Health & Metrics**: Actuator endpoints with Prometheus integration
- **Container Security**: Multi-stage Docker build, non-root user (UID 1000)
- **Pod Security Standards**: Baseline PSS enforcement with proper security contexts
- **High Availability**: Multi-AZ deployment with pod anti-affinity rules
- **Auto-scaling**: Horizontal Pod Autoscaler based on CPU/memory
- **Progressive Deployments**: Automated canary rollouts with traffic shifting
- **Service Discovery**: Kubernetes services with Istio virtual services

```

## 🛡️ Security Features

- **Non-root container**: Application runs as user 1000
- **RBAC**: Proper Kubernetes service accounts
- **Network policies**: Istio security policies (when enabled)
- **Pod security**: Security contexts configured
- **Pod Security Standards (PSS)**: Baseline level enforcement


### Karpenter Node Provisioning

- Automatic node scaling based on pod requirements
- Cost optimization with spot instances
- Multi-AZ deployment for high availability

## 📄 License

This project is licensed under the terms specified in the LICENSE.txt file.

---
