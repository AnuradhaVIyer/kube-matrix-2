# **Kube-Matrix Developer Guide** 

# **⭐ 1\. Prerequisites**

## **Install AWS CLI**

Mac:

`brew install awscli`

Ubuntu:

`sudo apt update`  
`sudo apt install awscli -y`

Windows:

* `Install from AWS MSI installer`.

### **Configure AWS CLI**

Run:

`aws configure`

Enter:

```AWS Access Key ID: <your key>  
AWS Secret Access Key: <your secret>  
Default region: us-east-1  
Output format: json
```
# **Install Docker on Ubuntu (Linux)**

### **Step 1 — Uninstall old versions (optional)**

`sudo apt-get remove docker docker-engine docker.io containerd runc`

### **Step 2 — Update packages**

`sudo apt-get update`

### **Step 3 — Install required packages**

`sudo apt-get install \`  
    `ca-certificates \`  
    `curl \`  
    `gnupg \`  
    `lsb-release -y`

### **Step 4 — Add Docker’s official GPG key**

`curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg`

### **Step 5 — Add Docker apt repository**

`echo \`  
  `"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \`  
  `$(lsb_release -cs) stable" | \`  
  `sudo tee /etc/apt/sources.list.d/docker.list > /dev/null`

### **Step 6 — Install Docker Engine**

`sudo apt-get update`  
`sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y`

### **Step 7 — Verify installation**

`docker --version`  
`docker run hello-world`

### **Step 8 — Allow running docker without sudo**

`sudo usermod -aG docker $USER`

# **Install kubectl on Ubuntu / Linux**

### **Step 1 — Download latest stable kubectl**

`curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"`

### **Step 2 — Make it executable**

`chmod +x kubectl`

### **Step 3 — Move it into PATH**

`sudo mv kubectl /usr/local/bin/`

### **Step 4 — Verify**

`kubectl version --client`

---

# **⭐ 2\. Generate kubeconfig (Two Methods)**

## **Method A — generate-kubeconfig.sh**

Use this script:

### **generate-kubeconfig.sh**

```bash
#!/bin/bash

# Script to generate kubeconfig for a developer for an existing EKS cluster
# -------------------------
# Configurable parameters
# -------------------------

CLUSTER_NAME=${1:-"<your-cluster-name>"}     # Default: replace with your cluster name
REGION=${2:-"us-east-1"}                   # Default: N. Virginia
KUBECONFIG_FILE=${3:-"$HOME/.kube/config"}  # Default kubeconfig location

# -------------------------
# Prerequisites check
# -------------------------

command -v aws >/dev/null 2>&1 || { echo >&2 "AWS CLI not installed. Exiting."; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo >&2 "kubectl not installed. Exiting."; exit 1; }

# -------------------------
# Generate kubeconfig
# -------------------------

echo "Generating kubeconfig for EKS cluster '$CLUSTER_NAME' in region '$REGION'..."
aws eks --region $REGION update-kubeconfig --name $CLUSTER_NAME --kubeconfig $KUBECONFIG_FILE

# -------------------------
# Test connection
# -------------------------

echo "Testing connection..."
kubectl get nodes

if [ $? -eq 0 ]; then
    echo "✅ Kubeconfig setup successful. You can now run kubectl commands."
else
    echo "❌ Failed to connect. Check your AWS credentials and cluster permissions."
fi
```
Run:

```chmod +x generate-kubeconfig.sh
./generate-kubeconfig.sh
```
Usage:

`bash generate-kubeconfig.sh <eks-cluster-name> <region-name>`

Example:

`bash generate-kubeconfig.sh km-dev-eks us-east-1`

Test:

`kubectl get nodes`

---

## 

## **Method B — No script, run from terminal**

```
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>
kubectl get nodes
```

You should see your EKS worker nodes.

---

# **⭐ 2\. Basic kubectl sanity tests**

---

# **Test 1 — Create a namespace**

```
kubectl create namespace sanity-test
kubectl get ns
```
---

## 

## **Test 2 — Simple NGINX Pod**

```# nginx-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-test
  namespace: sanity-test
spec:
  containers:
    - name: nginx
      image: nginx:latest
      ports:
        - containerPort: 80
```
Apply:

`kubectl apply -f nginx-pod.yaml`

`kubectl get pods -n sanity-test`

`kubectl logs nginx-test -n sanity-test`

---


## **Test 3 — NGINX Deployment**

```
# nginx-deploy.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
  namespace: sanity-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
        - name: nginx
          image: nginx
```
Apply:

`kubectl apply -f nginx-deploy.yaml`

`kubectl get deploy -n sanity-test`

`kubectl get pods -n sanity-test`

---

## **Test 4 — LoadBalancer Service (ALB or NLB)**

### **service.yaml**

```
#service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-lb
  namespace: sanity-test
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```
Apply:

`kubectl apply -f service.yaml`

`kubectl get svc -n sanity-test`

Within a minute, AWS will assign an external LB hostname.

Test in browser:

`http://<external-lb-dns>`

---
## **Test 5 — Destroy Sanity-Test Namespace**
`kubectl delete namespace sanity-test`
---
# **⭐ 3. Login to ECR (VERY IMPORTANT)**

ECR requires a password-based login using AWS CLI.

Run:

`aws ecr get-login-password --region us-east-1 \`  
`| docker login --username AWS --password-stdin <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com`

Replace `<AWS_ACCOUNT_ID>` with your 12-digit account ID.

---

# **⭐ 4. Build Docker Image**

From your project root or whichever directory:

### **Example for frontend:**

**Dockerfile**

```
# Use Node.js LTS as base image
FROM node:18

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY . .

# Expose the Next.js port
EXPOSE 3000

# Start Next.js in development mode
RUN npm run build
CMD ["npm", "start"]

```
Run the following:

`docker build -t frontend-app .`

### **Example for Backend:**

**Dockerfile**

```
# ---------- Build Stage ----------

# Use Node.js LTS as base image
FROM node:18

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files
COPY . .

# Expose the port the backend runs on
EXPOSE 3001

# Start the backend server
CMD ["node", "src/server.js"]

```
Run this command:

`docker build -t backend-app .`


---

# **⭐ 5. Tag the Image (VERY IMPORTANT)**

You must tag the local image with the ECR repository URL.

Use this format:

`<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/<repo-name>:<tag>`

### **Frontend:**

`docker tag frontend-app:latest \`  
`<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/frontend-repo:latest`

### **Backend:**

`docker tag backend-app:latest \`  
`<AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/backend-repo:latest`

---

# **⭐ 6. Push Image to ECR**

### **Frontend push:**

`docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/frontend-repo:latest`

### **Backend push:**

`docker push <AWS_ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com/backend-repo:latest`

---

# **⭐ 7. Verify That Images Are in ECR**

`aws ecr describe-images \`  
  `--repository-name frontend-repo \`  
  `--region us-east-1`

Repeat for backend.

---

# **⭐ Your Repositories From Terraform**

Since you created:

* `frontend-repo`

* `backend-repo`

* `database-repo`

The URLs should look like:

123456789012.dkr.ecr.us-east-1.amazonaws.com/frontend-repo  
123456789012.dkr.ecr.us-east-1.amazonaws.com/backend-repo  
123456789012.dkr.ecr.us-east-1.amazonaws.com/database-repo

---

# **⭐ 8. Deploy book-review application**

Here are the manifest files.

---
## **Namespace**
*namespace.yaml*  
```
apiVersion: v1
kind: Namespace
metadata:
  name: book-review
```  
## **Frontend Deployment**

*frontend-deployment.yaml*

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: book-review-frontend
  namespace: book-review
spec:
  replicas: 2
  selector:
    matchLabels:
      app: book-review-frontend
  template:
    metadata:
      labels:
        app: book-review-frontend
    spec:
      containers:
        - name: frontend
          image: REPLACE_FRONTEND_IMAGE  # will be overridden by kubectl set image
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 3000
          env:
            - name: NEXT_PUBLIC_API_URL
              value: "/" # or external URL if backend LB exposed
```
#### **Service file:**

*frontend-service.yaml*

```
apiVersion: v1
kind: Service
metadata:
  name: book-review-frontend
  namespace: book-review
spec:
  type: ClusterIP
  selector:
    app: book-review-frontend
  ports:
    - protocol: TCP
      port: 3000
      targetPort: 3000
```
---

## **Backend Deployment**

*backend-deployment.yaml*

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: book-review-backend
  namespace: book-review
spec:
  replicas: 2
  selector:
    matchLabels:
      app: book-review-backend
  template:
    metadata:
      labels:
        app: book-review-backend
    spec:
      containers:
        - name: backend
          image: REPLACE_BACKEND_IMAGE  # will be overridden by kubectl set image
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 3001

          env:
            - name: DB_HOST
              valueFrom:
                secretKeyRef:
                  name: book-review-backend-env
                  key: DB_HOST

            - name: DB_NAME
              valueFrom:
                secretKeyRef:
                  name: book-review-backend-env
                  key: DB_NAME

            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: book-review-backend-env
                  key: DB_USER

            - name: DB_PASS
              valueFrom:
                secretKeyRef:
                  name: book-review-backend-env
                  key: DB_PASS

            - name: DB_DIALECT
              valueFrom:
                secretKeyRef:
                  name: book-review-backend-env
                  key: DB_DIALECT

            - name: JWT_SECRET
              valueFrom:
                secretKeyRef:
                  name: book-review-backend-env
                  key: JWT_SECRET

            - name: ALLOWED_ORIGINS
              value: "http://localhost:3000,http://k8s-bookrevi-bookrevi-0fdc24b76f-1877726053.us-east-1.elb.amazonaws.com"

          resources:
            requests:
              cpu: "250m"
              memory: "256Mi"
            limits:
              cpu: "500m"
              memory: "512Mi"

      restartPolicy: Always
```
*backend-service.yaml*  
```
apiVersion: v1
kind: Service
metadata:
  name: book-review-backend
  namespace: book-review
spec:
  type: ClusterIP  # internal only
  selector:
    app: book-review-backend
  ports:
    - protocol: TCP
      port: 3001       # port that frontend calls
      targetPort: 3001 # container port
```

*ingress.yaml*  
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: book-review-ingress
  namespace: book-review
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: book-review-frontend
                port:
                  number: 3000
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: book-review-backend
                port:
                  number: 3001
```

---

# **⭐ 9. EKS → Aurora Serverless Connection Test**

**From a pod:**

`kubectl run sqltest --image=mysql:8 -it --rm -- bash`

**Inside the pod:**

`mysql -h <aurora-endpoint> -u admin -p`

If this works → networking & SGs are correct.

# **Connect to EKS Cluster**

### **Option 1: If you have the generate-kubeconfig.sh**

Run:

`./generate-kubeconfig.sh`

---

### **Option 2: Using AWS CLI**

`aws eks update-kubeconfig --name <your-cluster-name> --region us-east-1`

Verify:

`kubectl get nodes`  
`kubectl get pods -A`  
`kubectl get deployments`

If you see nodes → you are connected.

---

# **⭐ Run YAML files (apply)**

Go to the folder where your YAMLs are stored, for example:

`cd k8s/`

Now run:

`kubectl apply -f .`

This applies **all YAML files in the folder**.

---

# **Or apply a single file:**

`kubectl apply -f namespace.yaml`
`kubectl apply -f backend-deployment.yaml`  
`kubectl apply -f backend-service.yaml`
`kubectl apply -f frontend-deployment.yaml`  
`kubectl apply -f frontend-service.yaml`  
`kubectl apply -f ingress.yaml`

# **Or Run Github Actions:**
Go to book-review repo actions and select *Build and Push Images* and select *Run Workflow*. This will build the Docker images and push it to AWS ECR repos.

Next select *Deploy to EKS*. This will deploy the application to AWS EKS cluster.
---
# **⭐ Check if everything is running**

### **Pods:**

`kubectl get pods`

### **Services:**

`kubectl get svc`

### **Logs:**

`kubectl logs -f deployment/backend`

### **Events:**

`kubectl get events --sort-by=.metadata.creationTimestamp`  

# **🔁 If you modify a file later**

Just reapply:

`kubectl apply -f backend-deployment.yaml`

No need to delete anything.

# **Or Run Github Actions:**
Go to book-review repo actions and select *Deploy to EKS* and select *Run Workflow*. This will reapply the changes and deploy the application to AWS EKS cluster.
---

# **❌ If you want to delete all pods and resources in a namespace and the namespace also**

Careful — but this works:

`kubectl delete namespace book-review`


# **Or Run Github Actions:**  

Go to book-review repo actions and select *Destroy Kubernetes Deployment* and select *Run Workflow*. This will delete the deployed book-review K8s pods, services and ingress along with namespace from the EKS cluster.  
Next select *Destroy ECR Images* and select *Run Workflow*. This will delete the book-review ECR images from the repo.
---

