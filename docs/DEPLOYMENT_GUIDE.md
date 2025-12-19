# ✅ **Kube-Matrix Deployment Guide (Full Step-by-Step Guide)**

# Deployment Guide  
AWS + Kubernetes Internal Developer Platform (IDP)

This guide provides step-by-step instructions to deploy the full Internal Developer Platform using Terraform and perform a Sanity test using Kubectl.

---

# 🧰 1. Prerequisites
Install the following tools:

### System Requirements
- AWS CLI v2  
- Terraform >= 1.5  
- Helm
- Docker
- kubectl 

### IAM Requirements
Your user/role must have permissions for:
- EC2  
- EKS  
- RDS  
- VPC  
- IAM  
- S3  
- DynamoDB  
- ECR

---

# 📦 2. Setup Terraform Backend

### 2.1.	Update the variables at bootstrap/bootstrap.tfvars
Like prefix - this is the prefix used in all the resource names
Environment - this is also used in resource names.
Bucket_prefix - This prefix is used to name the S3 bucket; combined with a suffix generated at runtime, it provides a unique S3 bucket name.
Dynamodb_table_name - stores the table name, not required to be unique.

### 2.2.	Run bootstrap-terraform.yml workflow to create S3 bucket and DynamoDB table.
  a. Add the below secrets to your GitHub Repository  
     a.1 AWS_ACCESS_KEY_ID  
     a.2 AWS_REGION  
     a.3 AWS_ROLE_ARN  
     a.4 AWS_SECRET_ACCESS_KEY  
  b.  Go to Actions -> Select "Bootstrap Terraform" in the list of option to the left under All Workflows.  
  c.	Click on "Run workflow"  
  d.	Verify successful run.  
 
 
### 2.3.	Validate Resources created in the below naming format
  a.	S3
  unique_bucket_name = "km-terraform-state-dev-20251205052111"
 
  b.	DynamoDB table
  dynamodb_table_name = "km-terraform-locks-dev-20251205052111"


### 2.4 Configure backend.tf(will be in the root folder like Kube-matrix)  with the details of S3 and DynamoDB created in the previous step.
```terraform {
  backend "s3" {
    bucket         = "<<prefix>>-terraform-state-dev-<<Datetime>>"
    dynamodb_table = "<<prefix>>-terraform-locks-dev-<<Datetime>>"
  }
}
```
Run:
```
terraform init -reconfigure
```
# 🌐 3. Set variables in the environment variable file(tfvars).
Navigate to environment
cd envs/

Set variables (dev.tfvars)
component              = "vpc"
vpc_cidr               = "10.0.0.0/16"
public_subnet_cidrs    = ["10.0.1.0/24","10.0.2.0/24"]
private_subnet_cidrs   = ["10.0.101.0/24","10.0.102.0/24"]


# ☸ 4. Deploy the modules - VPC, Subnets, NATs, IGw, Security Groups, EKS, ECR, Aurora MySQL, IAM Role
  a. Terraform Plan  
      ```
      terraform plan -var-file="./envs/dev.tfvars"  
      ```  

  b. Terraform Apply  
      ```
      terraform apply -var-file="./envs/dev.tfvars" -auto-apply  
      ```  
OR  
  c. Github Action *Terraform Deployment*  
     Go to Github Action, select *Terraform Deployment* and click on Run workflow. Select the appropriate branch and environment. The workflow will start.  

*Output shown by terraform:*  
alb_irsa_role_arn  
autoscaler_irsa_role_arn  
aurora_cluster_endpoint  
aurora_reader_endpoint  
cloudwatch_log_group  
ecr_frontend_repository_url  
ecr_frontend_policy_arn  
ecr_backend_repository_url  
ecr_backend_repository_url  
aws_region  
eks_cluster_ca_certificate  
eks_cluster_endpoint  
eks_cluster_name  
eks_node_group_name  
eks_oidc_provider_arn  
nat_gateway_ids  
private_subnet_cidrs  
private_subnet_ids  
public_subnet_cidrs  
public_subnet_ids  
security_group_ids  
vpc_id  

Not showing in output but present
- Credentials stored in SSM Parameter Store


To validate SSM parameters:
```
aws ssm get-parameter --name "/km/dev/db/master_password" --with-decryption --region us-east-1
```

# 🧮 5. Generate Kubeconfig
```
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>
kubectl get nodes
```
You should see your EKS worker nodes

# 🧪 6. Basic kubectl sanity tests**
All YAML files for sanity test are stored in the sanity-test folder
```cd sanity-test
ls
```
Output will show:
nginx-pod.yaml
nginx-deploy.yaml
service.yaml
---

## **Test 1 — Create a namespace**

```kubectl create namespace sanity-test
kubectl get ns
```
---

## 

## **Test 2 — Simple NGINX Pod**

```kubectl apply -f nginx-pod.yaml
kubectl get pods -n sanity-test
kubectl logs nginx-test -n sanity-test
```
---

## 

## **Test 3 — NGINX Deployment**

```kubectl apply -f nginx-deploy.yaml
kubectl get deploy -n sanity-test
kubectl get pods -n sanity-test
```
---
##
## **Test 4 — LoadBalancer Service (ALB or NLB)**

```kubectl apply -f service.yaml
kubectl get svc -n sanity-test
```
Within a minute, AWS will assign an external LB hostname.

Test in browser:
```
`http://<external-lb-dns>`
```

##

# 🏁 7. Final Verification Checklist
- *Component Status*
- Terraform backend    ✅
- VPC & subnets	       ✅
- NAT, IGW, Routes	   ✅
- Security groups	     ✅
- EKS cluster	         ✅
- Node groups	         ✅
- Kubeconfig works	   ✅
- Aurora DB	           ✅
- ECR repos	           ✅
- Sample app deployed	 ✅

---
# 🎉 8. Deployment Complete!
You now have a fully functional AWS + Kubernetes Internal Developer Platform ready for application deployments, CI/CD integration, monitoring, and more.

---

# 🗑️ 9. Cleanup
`kubectl delete namespace sanity-test`

The above command will delete the pods, deployment and service inside the sanity-test namespace including the namespace.

Destroy the Infrastructure  
a. Terraform destroy  
   `terraform destroy -var-file="./envs/dev.tfvars" -auto-apply`  
OR  
c. Github Action *Destroy Deployment*  
   Go to Github Action, select *Destroy Deployment* and click on Run workflow. Select the appropriate branch and environment. The workflow will start.  

     This will destroy the infrastructure setup in the appropriate environment.

---