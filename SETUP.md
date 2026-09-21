# Setup Guide - Multi-Cloud Infrastructure

## Quick Start

### 1. Initialize State Storage

**AWS S3 Bucket:**

```bash
cd aws/Init
terraform init
terraform apply
```

**DigitalOcean Spaces Bucket:**

```bash
cd digitalocean/Init
terraform init
terraform apply
```

**Cloudflare DNS (Terraform Cloud):**

```bash
cd shared/cloudflare
# Update backend.tf with your Terraform Cloud details
terraform init
terraform apply
```

### 2. Configure Backend Files

Copy the backend examples to your configurations:

**AWS Backend:**

```bash
cp aws/Init/backend.tf.example aws/stage/networking/backend.tf
# Update the key path in backend.tf
```

**DigitalOcean Backend:**

```bash
cp digitalocean/Init/backend.tf.example digitalocean/stage/doks/backend.tf
# Update the key path in backend.tf
```

### 3. Set Environment Variables

**AWS:**

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

**DigitalOcean:**

```bash
export DIGITALOCEAN_TOKEN="your-do-api-token"
export SPACES_ACCESS_KEY_ID="your-spaces-key"
export SPACES_SECRET_ACCESS_KEY="your-spaces-secret"
```

**Cloudflare:**

```bash
export CLOUDFLARE_API_TOKEN="your-cloudflare-token"
export CLOUDFLARE_ACCOUNT_ID="your-account-id"
```

### 4. Deploy Infrastructure

**Stage Environment:**

```bash
# AWS Stage
cd aws/stage/networking && terraform apply
cd ../eks && terraform apply
cd ../loadbalancer && terraform apply

# DigitalOcean Stage
cd digitalocean/stage/doks && terraform apply
cd ../loadbalancer && terraform apply
```

**Production Environment:**

```bash
# AWS Prod
cd aws/prod/networking && terraform apply
cd ../eks && terraform apply
cd ../loadbalancer && terraform apply

# DigitalOcean Prod
cd digitalocean/prod/doks && terraform apply
cd ../loadbalancer && terraform apply
```

## Directory Structure

```
terraform/
├── aws/                    # AWS infrastructure (S3 state)
├── digitalocean/           # DO infrastructure (Spaces state)
├── shared/                 # Shared resources (Terraform Cloud state)
├── traffic-control/        # DNS routing
└── modules/               # Reusable modules
```

## State Management

- **AWS** → S3 + DynamoDB locking
- **DigitalOcean** → Spaces with versioning
- **Cloudflare** → Terraform Cloud

## Traffic Shifting

```bash
# Shift to AWS
cd shared/cloudflare
terraform apply -var="prod_load_balancer_ip=aws-lb-ip"

# Shift to DigitalOcean
terraform apply -var="prod_load_balancer_ip=do-lb-ip"
```
