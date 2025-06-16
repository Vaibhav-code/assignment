
# Node.js App Deployment on AWS ECS Fargate with Terraform

This project demonstrates how to deploy a containerized Node.js application to **AWS ECS Fargate** using **Terraform**. It also includes TLS certificate generation for secure access and environment variable injection into the container.

---

## 📁 Project Structure

```
.
├── Dockerfile
├── index.js
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── ...
├── tls.crt
├── tls.key
└── README.md
```

---

## 🚀 Features

- Node.js Express web app
- Dockerized application
- Pushed to **Amazon ECR**
- Deployed to **ECS Fargate** with **ALB**
- Environment variable (`SECRET_WORD`) injected
- **TLS self-signed certificate** created and imported into AWS ACM
- Optional: Setup for custom domain and HTTPS via **Route 53**

---

## 🛠️ Technologies Used

- Node.js (Express)
- Docker
- AWS (ECS, Fargate, ECR, ACM, ALB, IAM)
- Terraform
- PowerShell (for local commands)

---

## 📦 Docker Instructions

### 1. Build Docker image
```bash
docker build -t ecs-node-app .
```

### 2. Tag the image
```bash
docker tag ecs-node-app:latest 476813399880.dkr.ecr.ap-south-1.amazonaws.com/ecs-node-app:latest
```

### 3. Push to ECR
```bash
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin 476813399880.dkr.ecr.ap-south-1.amazonaws.com
docker push 476813399880.dkr.ecr.ap-south-1.amazonaws.com/ecs-node-app:latest
```

---

## ☁️ Terraform Setup

### Key Resources
- `aws_ecs_cluster`
- `aws_ecs_task_definition`
- `aws_ecs_service`
- `aws_lb`, `aws_lb_target_group`, `aws_lb_listener`
- `aws_security_group`, `aws_vpc`, `aws_subnet`
- `aws_iam_role`, `aws_iam_policy_attachment`

### Example: Injecting ENV Variables

```hcl
environment = [
  {
    name  = "SECRET_WORD"
    value = "rearcrocks"
  }
]
```

---

## 🔐 TLS Certificate (Self-Signed)

### 1. Generate Certificate & Key (PowerShell)
```bash
openssl req -x509 -newkey rsa:2048 -nodes `
  -keyout tls.key `
  -out tls.crt `
  -days 365 `
  -subj "/CN=example.com"
```

### 2. Import Certificate to AWS ACM
```powershell
aws acm import-certificate `
  --certificate fileb://tls.crt `
  --private-key fileb://tls.key `
  --certificate-chain fileb://tls.crt `
  --region ap-south-1
```

---

## 🔄 Redeploy ECS Service (if image/env changed)

```powershell
aws ecs update-service `
  --cluster node-app-cluster `
  --service node-app-service `
  --force-new-deployment `
  --region ap-south-1
```

---

## 🌐 Access the App

Use the **Load Balancer DNS URL** (from Terraform output or AWS console):

```text
http://node-app-alb-12715612.ap-south-1.elb.amazonaws.com
```

To enable HTTPS, associate your domain via Route 53 and use the imported ACM certificate.

---

## 📘 Next Steps (Optional)

- Register a custom domain in Route 53
- Point the domain to your Load Balancer
- Set up HTTPS using a public ACM certificate
- Set up CI/CD pipeline using GitHub Actions

---

## 🙌 Author

**Vaibhav Srivastava**  
Deployed using AWS ECS Fargate + Terraform

---

