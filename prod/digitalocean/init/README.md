# DigitalOcean Spaces Init Configuration

This directory contains the Terraform configuration to create a DigitalOcean Spaces bucket for storing Terraform state files.

## Setup Instructions

### 1. Set up DigitalOcean API Token

```bash
export DIGITALOCEAN_TOKEN="your-do-api-token"
```

### 2. Initialize and Apply

```bash
cd prod/digitalocean/Init
terraform init
terraform plan
terraform apply
```

### 3. Get the bucket details

```bash
terraform output
```

## Using the State Bucket

After creating the bucket, you can use it in other Terraform configurations:

1. Copy `backend.tf.example` to your module
2. Update the bucket name and key path
3. Set your Spaces access keys:
   ```bash
   export SPACES_ACCESS_KEY_ID="your-access-key"
   export SPACES_SECRET_ACCESS_KEY="your-secret-key"
   ```

## Configuration

- **Bucket Name**: `terraform-state-prod` (configurable via `environment` variable)
- **Region**: `nyc3` (configurable via `region` variable)
- **Versioning**: Enabled for state file safety
- **Lifecycle Rules**: Clean up old versions after 30 days
- **CORS**: Enabled for web access (optional)

## Security Notes

- The bucket is created with versioning enabled for state file safety
- Consider adding bucket policies for additional security
- Use IAM roles/keys with minimal required permissions
- Consider enabling server-side encryption if needed
