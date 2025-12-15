# **kube-matrix-2**

## **Overview**

**kube-matrix-2** #(AWS + Kubernetes Internal Developer Platform (IDP))# is a structured, modular Kubernetes deployment framework designed to manage multiple environments consistently. It enables teams to follow GitOps principles, reuse modules, automate deployments, and maintain clean, scalable environment configuration.

It is a fully automated, production-grade Internal Developer Platform (IDP) that enables development teams to deploy, scale, and manage cloud-native applications on AWS using Kubernetes (EKS). The platform is provisioned entirely through Terraform following best practices for multi-account, multi-region architectures.

This project aims to standardize how Kubernetes environments (dev, staging, prod) are defined, bootstrapped, and deployed.

---

## **Key Features**

* Multi-environment Kubernetes configuration

* Clean directory-based separation of concerns

* Reusable modules for infra and application deployments

* GitOps-friendly repo structure

* Automation workflows (GitHub Actions)

* Sanity test suite for quick verification

---

## **Directory Structure**

Below is the simplified directory layout of the project:

kube-matrix-2/  
 ├── .github/  
 │    └── workflows/            \# CI/CD pipelines and automation  
 ├── bootstrap/                 \# Bootstrap scripts for maintaining terraform state  
 ├── docs/                      \# Documentation and guides  
 ├── envs/                      \# Environment configs (dev, stage, prod, etc.)  
 │    ├── dev/  
 │    ├── stage/  
 │    └── prod/  
 ├── modules/                   \# Reusable modules (K8s components, infra, etc.)  
 ├── scripts/                   \# Helper scripts (apply, validate, lint, etc.)  
 ├── sanity-test/               \# Smoke tests to verify deployments  
 ├── LICENSE (optional)  
 └── README.md

---

## **Prerequisites**

Before using this repo, ensure you have:

* Cloud provider credentials and roles if provisioning resources

* Git installed

* Terraform installed

* `kubectl` installed and configured

* IAM user/role with admin privileges

* SSH key (Dev only, if using Bastion)


---
## 📌 Project Implementation
This project implements an enterprise-grade Internal Developer Platform with:

- Terraform S3 backend + DynamoDB Lock Table
- AWS Networking (VPC, Subnets, NAT, IGW, Endpoints)
- Amazon EKS Cluster with ALB and Autoscaling controllers
- Aurora MySQL Serverless v2 Database
- Amazon ECR for container image storage
- IAM roles, policies, and security boundaries
- Developer access via kubeconfig generation
- CI/CD-ready environment separation (Dev, Stage, Prod)

## **Getting Started**

### **1\. Clone the repository**

````
git clone https://github.com/AnuradhaVIyer/kube-matrix-2.git  
cd kube-matrix-2
````

### **2\. Bootstrap your environment**

Use the scripts in `bootstrap/` to initialize s3 bucket and dynamodb for maintaining terraform state.

### **3\. Configure your environment**

Modify values in `envs/<environment>` to suit your cluster.

### **4\. Deploy modules**

Use the files under `modules/` to deploy workloads and infrastructure.

### **5\. Run sanity tests**

Execute items under `sanity-test/` to validate deployments and connectivity.

---

## **How to Fork the Repository**

If you want to contribute or customize your own flow:

1. Go to the GitHub repo page:  
    `https://github.com/AnuradhaVIyer/kube-matrix-2`

2. Click **Fork** in the top-right corner

3. Select your GitHub account

4. GitHub creates a forked copy under your profile

You now have your own editable version.

---

## **How to Work With a Fork**

### **1\. Clone your fork**

````
git clone https://github.com/\<your-username\>/kube-matrix-2.git  
cd kube-matrix-2
````
### **2\. Add the original repo as an upstream remote**

````
git remote add upstream https://github.com/AnuradhaVIyer/kube-matrix-2.git
````
### **3\. Keep your fork updated**

````
git fetch upstream  
git merge upstream/main
````
(or `git rebase upstream/main` if you prefer clean history)

---

## **How to Raise a Pull Request (PR)**

1. Create a new branch for your change:

    ````git checkout \-b feature/my-change  ````
2. Make your modifications (code, docs, fixes, etc.)  
3. Commit your changes:  
    ````
    git add .  
   git commit \-m "Describe the change"
   ````
4. Push the branch to your fork:

    ````git push origin feature/my-change ```` 
5. Go to your fork on GitHub

6. GitHub automatically shows a **“Compare & Pull Request”** banner

7. Click **Open Pull Request**

8. Fill in details, description, and submit

Your PR will now be visible in the main repository for review.

---

## **Contribution Guidelines**

* Follow the directory structure and naming conventions

* Update documentation when modifying behavior

* Run sanity tests before raising a PR

* Keep commits meaningful and clean
