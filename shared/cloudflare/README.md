# Cloudflare DNS Configuration

This directory contains the Terraform configuration for managing DNS records and settings in Cloudflare using Terraform Cloud for state management.

## State Management

**State is managed by Terraform Cloud** to ensure:

- ✅ State locking and versioning
- ✅ Team collaboration
- ✅ Run history and audit trails
- ✅ Secure variable management
- ✅ No single point of failure

## Setup Instructions

### 1. Create Terraform Cloud Workspace

1. Go to [Terraform Cloud](https://app.terraform.io)
2. Create a new organization (if you don't have one)
3. Create a new workspace called `shared-cloudflare`
4. Set the workspace to use "CLI-driven workflow"

### 2. Configure Cloudflare API Token

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
2. Create a new token with:
   - **Zone:Zone:Edit** permissions
   - **Zone:Zone:Read** permissions
   - **Account:Account:Read** permissions

### 3. Set Terraform Cloud Variables

In your Terraform Cloud workspace, set these variables:

**Terraform Variables:**

```
cloudflare_api_token = "your-api-token"
cloudflare_account_id = "your-account-id"
domain_name = "yourdomain.com"
```

**Environment Variables:**

```
TF_VAR_cloudflare_api_token = "your-api-token"
TF_VAR_cloudflare_account_id = "your-account-id"
TF_VAR_domain_name = "yourdomain.com"
```

### 4. Initialize and Apply

```bash
cd shared/cloudflare
terraform init
terraform plan
terraform apply
```

## DNS Records Created

### Production Records:

- `yourdomain.com` → Production load balancer
- `www.yourdomain.com` → CNAME to main domain
- `api.yourdomain.com` → Production API gateway

### Staging Records:

- `stage.yourdomain.com` → Staging load balancer
- `api-stage.yourdomain.com` → Staging API gateway

## Traffic Shifting

To shift traffic between clouds, update the DNS record values:

```bash
# Shift production to AWS EKS
terraform apply -var="prod_load_balancer_ip=aws-lb-ip"

# Shift production to DigitalOcean DOKS
terraform apply -var="prod_load_balancer_ip=do-lb-ip"

# Shift staging to AWS EKS
terraform apply -var="stage_load_balancer_ip=aws-stage-lb-ip"

# Shift staging to DigitalOcean DOKS
terraform apply -var="stage_load_balancer_ip=do-stage-lb-ip"
```

## Benefits of Terraform Cloud

1. **State Locking**: Prevents concurrent modifications
2. **Version History**: Track all DNS changes
3. **Team Access**: Multiple people can manage DNS
4. **Audit Trail**: See who made what changes when
5. **Variable Management**: Secure storage of API tokens
6. **Remote Execution**: Run from anywhere with proper credentials

## Security Features

- **SSL/TLS**: Full SSL with minimum TLS 1.2
- **HTTPS Redirect**: Always use HTTPS
- **Security Level**: Medium security level
- **Browser Check**: Challenge suspicious requests
- **Privacy Pass**: Enhanced privacy protection
- **Minification**: CSS, HTML, and JS optimization
