# Multi-Cloud Kubernetes Infrastructure

This repository contains Terraform configurations for managing Kubernetes clusters across AWS EKS and DigitalOcean DOKS with the ability to shift traffic between environments dynamically using Cloudflare DNS.

## Architecture

```
Cloudflare DNS/Proxy
    ↓
Traffic Control (A/CNAME records)
    ↓
Stage Environment → EKS-Stage OR DOKS-Stage
    ↓
Prod Environment → EKS-Prod OR DOKS-Prod
```

## Directory Structure

```
terraform/
├── aws/                             # AWS infrastructure (State in AWS S3)
│   ├── Init/                        # S3 bucket for AWS state storage
│   ├── stage/
│   │   ├── networking/              # VPC, subnets, security groups
│   │   ├── eks/                     # EKS cluster for stage
│   │   └── loadbalancer/            # ALB/NLB for stage
│   └── prod/
│       ├── networking/              # VPC, subnets, security groups
│       ├── eks/                     # EKS cluster for prod
│       └── loadbalancer/            # ALB/NLB for prod
├── digitalocean/                    # DigitalOcean infrastructure (State in DO Spaces)
│   ├── Init/                        # Spaces bucket for DO state storage
│   ├── stage/
│   │   ├── doks/                    # DOKS cluster for stage
│   │   └── loadbalancer/            # Load balancer for stage
│   └── prod/
│       ├── doks/                    # DOKS cluster for prod
│       └── loadbalancer/            # Load balancer for prod
├── shared/                          # Shared resources across all environments
│   ├── cloudflare/                  # Cloudflare DNS and proxy configuration
│   ├── monitoring/                  # Cross-cloud monitoring
│   └── security/                    # Shared security policies
├── traffic-control/                  # Traffic shifting and routing
│   ├── stage/
│   └── prod/
└── modules/                         # Reusable Terraform modules
    ├── kubernetes/
    ├── loadbalancer/
    └── dns-record/
```

## State Management

**No single point of failure** - Each cloud's state is isolated:

- **AWS Infrastructure** → State stored in AWS S3 + DynamoDB locking
- **DigitalOcean Infrastructure** → State stored in DO Spaces
- **Cloudflare DNS** → State managed via Terraform Cloud

## Key Features

- ✅ **Instant traffic shifting** via Cloudflare DNS changes
- ✅ **Cloud-native state storage** - Each cloud uses its own storage
- ✅ **Independent failure domains** - One cloud's failure doesn't affect others
- ✅ **Environment parity** - Identical deployments across clouds
- ✅ **Zero-downtime migrations** - DNS-based traffic routing

## Traffic Shifting

```bash
# Shift production traffic to AWS EKS
terraform apply -var="prod_load_balancer_ip=aws-lb-ip"

# Shift production traffic to DigitalOcean DOKS
terraform apply -var="prod_load_balancer_ip=do-lb-ip"
```

## Getting Started

1. **Initialize State Storage**

   ```bash
   # AWS S3 bucket
   cd aws/Init
   terraform init && terraform apply

   # DigitalOcean Spaces bucket
   cd digitalocean/Init
   terraform init && terraform apply

   # Cloudflare DNS (Terraform Cloud)
   cd shared/cloudflare
   terraform init && terraform apply
   ```

2. **Deploy Infrastructure**

   ```bash
   # Deploy AWS infrastructure
   cd aws/stage/networking
   terraform init && terraform apply

   # Deploy DigitalOcean infrastructure
   cd digitalocean/stage/doks
   terraform init && terraform apply
   ```

3. **Configure Traffic Control**
   ```bash
   cd traffic-control/stage
   terraform init && terraform apply
   ```

## Benefits

- **Resilience** - Each cloud's failure doesn't affect others
- **Security** - State isolation per cloud provider
- **Performance** - State stored close to infrastructure
- **Cost** - Use each cloud's native storage
- **Simplicity** - Each team uses familiar tools
