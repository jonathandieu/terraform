# DigitalOcean Kubernetes Service (DOKS) - Production

This directory contains the Terraform configuration for the production DOKS cluster.

## Prerequisites

1. **State bucket must exist**: Run `prod/digitalocean/init` first to create the Spaces bucket
2. **DigitalOcean API token**: Set `DIGITALOCEAN_TOKEN` environment variable
3. **Spaces access keys**: Set `SPACES_ACCESS_KEY_ID` and `SPACES_SECRET_ACCESS_KEY` for backend access

## Setup

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your desired values
```

### 2. Set Credentials

```bash
export DIGITALOCEAN_TOKEN="your-do-api-token"
export SPACES_ACCESS_KEY_ID="your-spaces-access-key"
export SPACES_SECRET_ACCESS_KEY="your-spaces-secret-key"
```

### 3. Initialize and Apply

```bash
terraform init
terraform plan
terraform apply
```

## Configuration

- **Backend**: Uses DigitalOcean Spaces bucket (`terraform-state-prod`)
- **State Key**: `doks/terraform.tfstate`
- **Cluster Name**: Configurable via `cluster_name` variable
- **Region**: Configurable via `region` variable
- **Kubernetes Version**: Configurable via `kubernetes_version` variable

## Outputs

After applying, you can get cluster information:

```bash
terraform output
```

To get the kubeconfig:

```bash
doctl kubernetes cluster kubeconfig save <cluster-name>
```

## Updating the Cluster

```bash
terraform plan
terraform apply
```

## Destroying the Cluster

⚠️ **Warning**: This will delete the entire cluster and all workloads!

```bash
terraform destroy
```


