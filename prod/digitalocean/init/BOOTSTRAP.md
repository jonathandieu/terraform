# Bootstrap Guide: DigitalOcean Terraform State Storage

This guide walks you through bootstrapping your Terraform state storage for DigitalOcean infrastructure.

## The Bootstrap Problem

You need a Spaces bucket to store Terraform state, but you need Terraform to create the bucket. This creates a chicken-and-egg problem. The solution is to bootstrap in stages:

1. **Stage 1**: Create the bucket using local state
2. **Stage 2**: Migrate the init configuration to use the bucket
3. **Stage 3**: Use the bucket for all other configurations

## Prerequisites

1. DigitalOcean API token with write permissions
2. DigitalOcean Spaces access keys (for backend authentication)
3. Terraform >= 1.0 installed

### Getting Your Credentials

1. **API Token**: Create at https://cloud.digitalocean.com/account/api/tokens
2. **Spaces Keys**: Create at https://cloud.digitalocean.com/account/api/spaces

## Bootstrap Steps

### Step 1: Create the State Bucket (Local State)

First, we'll create the bucket using local state:

```bash
cd prod/digitalocean/init

# Set your DigitalOcean API token
export DIGITALOCEAN_TOKEN="your-do-api-token"

# Initialize Terraform (will use local state)
terraform init

# Review the plan
terraform plan

# Create the bucket
terraform apply
```

After this step, you'll have a Spaces bucket created, but Terraform's state is still stored locally.

### Step 2: Get the Bucket Name

After creating the bucket, get its name:

```bash
terraform output state_bucket_name
```

Note the bucket name (it should be `terraform-state-prod` based on your terraform.tfvars).

### Step 3: Configure Backend for Init

Now we'll configure the init configuration to store its own state in the bucket:

```bash
# Copy the backend example
cp backend.tf.example backend.tf

# Edit backend.tf and update:
# - bucket: Use the bucket name from Step 2 (terraform-state-prod)
# - key: Set to "init/terraform.tfstate"
# - endpoint: Match your region (e.g., nyc3.digitaloceanspaces.com)
```

The backend.tf should look like:
```hcl
terraform {
  backend "s3" {
    endpoint                    = "nyc3.digitaloceanspaces.com"
    bucket                     = "terraform-state-prod"
    key                        = "init/terraform.tfstate"
    region                     = "us-east-1"
    skip_credentials_validation = true
    skip_metadata_api_check    = true
    force_path_style           = true
  }
}
```

### Step 4: Set Spaces Credentials and Migrate State

```bash
# Set your Spaces access keys
export SPACES_ACCESS_KEY_ID="your-spaces-access-key"
export SPACES_SECRET_ACCESS_KEY="your-spaces-secret-key"

# Re-initialize with the new backend
terraform init

# When prompted, type "yes" to migrate existing state to the new backend
```

### Step 5: Verify

```bash
# Verify the state is now remote
terraform state list

# Check outputs
terraform output
```

## Using the Bucket for DOKS

Now that the bucket exists and the init config uses it, you can set up your DOKS cluster:

1. Navigate to your DOKS directory
2. Create a `backend.tf` file pointing to the bucket
3. Set the key path (e.g., `doks/terraform.tfstate`)
4. Initialize and apply

See the main README.md for details on configuring backends for other modules.

## Troubleshooting

### Error: "Backend configuration changed"
- This is normal when migrating from local to remote state
- Run `terraform init` and confirm the migration

### Error: "Access Denied" when using backend
- Verify your Spaces access keys are set correctly
- Check that the keys have read/write permissions
- Ensure the bucket name matches exactly

### Error: "Bucket not found"
- Make sure you've completed Step 1 (created the bucket)
- Verify the bucket name in backend.tf matches the created bucket
- Check the region/endpoint matches

## Security Best Practices

1. **Never commit credentials**: Use environment variables or a secrets manager
2. **Enable versioning**: Already configured in main.tf
3. **Use least privilege**: Create Spaces keys with minimal required permissions
4. **Rotate keys regularly**: Update your Spaces keys periodically
5. **Enable encryption**: Consider adding server-side encryption to the bucket
