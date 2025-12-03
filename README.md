# AWS + Kubernetes Internal Developer Platform (IDP)
A fully automated, production-grade Internal Developer Platform (IDP) that enables development teams to deploy, scale, and manage cloud-native applications on AWS using Kubernetes (EKS). The platform is provisioned entirely through Terraform following best practices for multi-account, multi-region architectures.

---

## 📌 Project Overview
This project implements an enterprise-grade Internal Developer Platform with:

- AWS Networking (VPC, Subnets, NAT, IGW, Endpoints)
- Amazon EKS Cluster (Fully managed Kubernetes)
- Aurora MySQL Serverless v2 Database
- Amazon ECR for container image storage
- Terraform S3 backend + DynamoDB Lock Table
- IAM roles, policies, and security boundaries
- Developer access via kubeconfig generation
- CI/CD-ready environment separation (Dev, Stage, Prod)

The platform is fully automated using Terraform modules:
modules/
├── network # VPC, Subnets, NAT, Endpoints
├── eks # EKS Cluster + Node Groups
├── database # Aurora MySQL
├── ecr # ECR Repositories + Policies
├── security # IAM roles/policies
envs/
├── dev
├── stage
└── prod

---

## 🚀 Core Principles
- **No hardcoding** of regions, partitions, account IDs, ARNs  
- **Multi-region & multi-account ready**
- **Strict naming & tagging conventions**
- **Developer access to Dev only**
- **Stage/Prod accessible only via CI/CD**
- **Parameter Store for all credentials**
- **Reusable, modular Terraform codebase**

---

## 🌐 Platform Architecture
### Includes:
- **VPC**
  - /16 CIDR  
  - 2 public + 2 private subnets  
  - NAT Gateway  
  - IGW  
  - Route Tables  
  - VPC Endpoints (S3 & SSM recommended)

- **EKS**
  - Latest supported K8s version  
  - Managed Node Groups  
  - Cluster Autoscaler  
  - ALB ingress support  
  - IAM roles for cluster + nodes  
  - Kubeconfig generator script

- **Aurora MySQL Serverless v2**
  - Private subnets only  
  - Auto-scaling  
  - Secrets stored in SSM Parameter Store  
  - SG rules allowing pod-to-DB access

- **ECR**
  - Repos: `frontend`, `backend`, `database`  
  - Lifecycle policies  
  - Least-privilege IAM policies  
  - CI/CD-only Prod access

- **Terraform Backend**
  - S3 bucket for tfstate  
  - DynamoDB table for tfstate locking  

---

## 🧩 Module Inputs & Outputs
Each module contains:
- `variables.tf` (inputs)
- `outputs.tf` (exported values)
- `main.tf` (resources)

Examples:
```bash
terraform output vpc_id
terraform output private_subnet_ids
terraform output eks_cluster_name
terraform output ecr_repo_urls

#########################################################
🧑‍💻 Developer Workflow

Build Docker Image

Authenticate to ECR

Tag and Push the image

Update deployment YAML

Apply to EKS via kubectl

Application available through ALB

##########################################################
📑 Documentation

This repository includes full documentation:

README.md – Overview (this file)

DEPLOYMENT_GUIDE.md – Detailed step-by-step deployment

DEVELOPER_GUIDE.md – Developer access guide, kubeconfig generation, ECR login, deployments

##########################################################
🧪 Testing

Test steps include:

Deploying example nginx pod

Testing ALB endpoint

Testing DB connectivity from pods

ECR push/pull tests

##########################################################
🛡 Security

IAM least privilege

Parameter Store for secrets

No hardcoding credentials

Restricted EKS endpoint (corp IP only for Stage/Prod)

DB access only from EKS pods (Stage/Prod)

#########################################################
📦 Prerequisites

AWS CLI v2

Terraform >= 1.5

kubectl

IAM user/role with admin privileges

SSH key (Dev only, if using Bastion)

#########################################################
🧰 Commands Summary
Initialize Terraform
terraform init

Validate
terraform validate

Plan
terraform plan -var-file=terraform.tfvars

Apply
terraform apply -var-file=terraform.tfvars

#########################################################
🏁 Conclusion

This IDP provides a highly secure, scalable, automated Kubernetes platform aligned with AWS best practices and enterprise requirements. It can be extended with CI/CD pipelines, monitoring (Grafana/Prometheus), logging (EFK), tracing, and service mesh.