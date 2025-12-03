# ✅ **DEPLOYMENT_GUIDE.md (Full Step-by-Step Guide)**

# Deployment Guide  
AWS + Kubernetes Internal Developer Platform (IDP)

This guide provides step-by-step instructions to deploy the full Internal Developer Platform using Terraform.

---

# 🧰 1. Prerequisites
Install the following tools:

### System Requirements
- AWS CLI v2  
- Terraform >= 1.5  
- kubectl  
- jq (optional)

### IAM Requirements
Your user/role must have permissions for:
- EC2  
- EKS  
- RDS  
- VPC  
- IAM  
- S3  
- DynamoDB  

---

# 📦 2. Setup Terraform Backend

### 2.1 Create S3 Bucket
aws s3api create-bucket --bucket km-terraform-state-<<Datetime>> --region us-east-1

### 2.2 Enable Versioning
aws s3api put-bucket-versioning \
  --bucket km-terraform-state-<<Datetime>> \
  --versioning-configuration Status=Enabled

### 2.3 Enable Public Access Block
aws s3api put-public-access-block \
  --bucket km-terraform-state-<<Datetime>> \
  --public-access-block-configuration \
    BlockPublicAcls=true \
    IgnorePublicAcls=true \
    BlockPublicPolicy=true \
    RestrictPublicBuckets=true

### 2.4 Create DynamoDB Lock Table
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST

### 2.5 Configure backend.tf
terraform {
  backend "s3" {
    bucket         = "km-terraform-state-<<Datetime>>"
    key            = "dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

Run:
terraform init -reconfigure

# 🌐 3. Deploy the VPC
Navigate to environment
cd envs/dev

Set variables (terraform.tfvars)
component              = "vpc"
vpc_cidr               = "10.0.0.0/16"
public_subnet_cidrs    = ["10.0.1.0/24","10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.101.0/24","10.0.102.0/24"]

Deploy
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars

# ☸ 4. Deploy EKS Cluster
Apply only the EKS module
Inside envs/dev/main.tf, ensure:
module "eks" { ... }

Then:
terraform apply -var-file=terraform.tfvars

Outputs will give:
cluster_name
cluster_endpoint
cluster_oidc_arn

# 🧮 5. Generate Kubeconfig
aws eks update-kubeconfig --region ap-south-1 --name km-eks-dev
kubectl get nodes

# 🗃 6. Deploy Aurora MySQL Serverless v2
Ensure DB module uses private subnets

Then:
terraform apply -var-file=terraform.tfvars

Retrieve DB endpoint:
terraform output db_endpoint
Credentials stored in SSM Parameter Store.

# 📦 7. Create ECR Repositories
Terraform will create:
km-frontend
km-backend
km-database

Test login
aws ecr get-login-password --region ap-south-1 \
| docker login --username AWS --password-stdin <your-aws-account>.dkr.ecr.ap-south-1.amazonaws.com

# 🧑‍💻 8. Developer Workflow (Image Build & Push)

Build
docker build -t frontend .

Tag 
docker tag frontend:latest <acct>.dkr.ecr.ap-south-1.amazonaws.com/km-frontend:latest

Push 
docker push <acct>.dkr.ecr.ap-south-1.amazonaws.com/km-frontend:latest

# 🧪 9. Test Deployment on EKS
Deploy NGINX
kubectl create namespace demo
kubectl apply -f nginx-deployment.yaml
kubectl apply -f nginx-service.yaml

Check ALB
kubectl get svc -n demo
Hit the URL to verify.

# 🔒 10. Security Controls
Dev: developer has cluster access

Stage/Prod: access via CI/CD only

DB accessible only from private subnets

EKS endpoint restricted to corporate CIDR in Stage/Prod

Secrets stored in SSM

# 🏁 Final Verification Checklist
Component	Status
Terraform backend   ✅
VPC & subnets	    ✅
NAT, IGW, Routes	✅
Security groups	    ✅
EKS cluster	        ✅
Node groups	        ✅
Kubeconfig works	✅
Aurora DB	        ✅
ECR repos	        ✅
Sample app deployed	✅

# 🎉 Deployment Complete!
You now have a fully functional AWS + Kubernetes Internal Developer Platform ready for application deployments, CI/CD integration, monitoring, and more.

---
