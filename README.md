# GCP Cloud Composer 2 - Production Terraform Configuration

Production-grade Terraform configuration for Google Cloud Composer 2 with a hardened security posture.

## Architecture

```
                         ┌──────────────────────────────────────────────┐
                         │              GCP Project                     │
                         │                                              │
                         │  ┌──────────────────────────────────────┐   │
                         │  │        VPC (Private, Custom)          │   │
                         │  │                                      │   │
                         │  │  ┌────────────────────────────────┐  │   │
                         │  │  │   Subnet (10.0.0.0/20)         │  │   │
                         │  │  │   + Pods range  (10.4.0.0/14)  │  │   │
                         │  │  │   + Svc range   (10.8.0.0/20)  │  │   │
                         │  │  │                                │  │   │
                         │  │  │  ┌──────────────────────────┐  │  │   │
                         │  │  │  │   Cloud Composer 2       │  │  │   │
                         │  │  │  │   (Private GKE Cluster)  │  │  │   │
                         │  │  │  │                          │  │  │   │
                         │  │  │  │  Scheduler │ Worker(s)   │  │  │   │
                         │  │  │  │  Web Server│ Triggerer   │  │  │   │
                         │  │  │  └──────────┬───────────────┘  │  │   │
                         │  │  │             │                  │  │   │
                         │  │  │  ┌──────────┴──────────┐       │  │   │
                         │  │  │  │  Cloud SQL (Private) │      │  │   │
                         │  │  │  └─────────────────────┘       │  │   │
                         │  │  └────────────────────────────────┘  │   │
                         │  │                                      │   │
                         │  │  Cloud Router ──► Cloud NAT ──► Internet│
                         │  └──────────────────────────────────────┘   │
                         │                                              │
                         │  ┌──────────┐  ┌───────────────────────┐    │
                         │  │ KMS Key  │  │ Service Account (SA)  │    │
                         │  │ (CMEK)   │  │ (Least Privilege)     │    │
                         │  └──────────┘  └───────────────────────┘    │
                         └──────────────────────────────────────────────┘
```

## Security Checklist

| Control | Implementation |
|---|---|
| Private IP environment | `enable_private_endpoint = true`, no public GKE endpoint |
| CMEK encryption | KMS key with 90-day rotation, bound to 6 service agents |
| Dedicated VPC | Custom VPC with `auto_create_subnetworks = false` |
| Private GKE cluster | Private nodes + master authorized networks (VPC only) |
| Least-privilege SA | Dedicated SA with only `composer.worker`, `logging.logWriter`, `monitoring.metricWriter` |
| Web server access control | IP allowlisting via `web_server_network_access_control` |
| Workload Identity | Composer 2 default + `ServiceAgentV2Ext` binding |
| Cloud SQL private IP | Private environment config with dedicated CIDR |
| Firewall rules | Default deny ingress, explicit allow for internal/health checks/IAP |
| VPC flow logs | Enabled on subnet with metadata included |
| Cloud NAT logging | Error logging enabled for outbound NAT |
| Firewall logging | Enabled on all firewall rules |
| Labels/tags | Applied to all resources via `common_labels` |
| Scheduled snapshots | Daily recovery snapshots at 04:00 UTC |
| Maintenance window | Defined weekly window (Sunday 00:00-04:00 UTC) |
| KMS key protection | `prevent_destroy = true` lifecycle rule |

## Prerequisites

- Terraform >= 1.5.0
- GCP project with billing enabled
- `gcloud` CLI authenticated with sufficient permissions
- Roles needed for the Terraform executor: `roles/editor` or scoped roles for Compute, Composer, KMS, IAM

## Usage

```bash
# 1. Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# 2. Edit with your project-specific values
vim terraform.tfvars

# 3. Initialize Terraform
terraform init

# 4. Review the execution plan
terraform plan

# 5. Apply
terraform apply
```

## CIDR Planning

| Range | Purpose | Default |
|---|---|---|
| `10.0.0.0/20` | Primary subnet | Nodes |
| `10.4.0.0/14` | Secondary range | GKE Pods |
| `10.8.0.0/20` | Secondary range | GKE Services |
| `172.16.0.0/28` | Master CIDR | GKE control plane |
| `10.10.0.0/24` | Cloud SQL | Airflow metadata DB |
| `172.31.245.0/24` | Composer network | Tenant project |

> **Note:** `172.17.0.0/16` is reserved by Cloud SQL and must not be used.

## Accessing Airflow

Since this is a private IP environment, the Airflow web UI is not accessible from the public internet. Access options:

1. **IAP Tunnel**: `gcloud compute ssh` with IAP forwarding
2. **VPN**: Connect to the VPC via Cloud VPN or Interconnect
3. **From within VPC**: Access from a VM in the same VPC

## Uploading DAGs

```bash
# Get the DAG bucket path from Terraform output
DAG_BUCKET=$(terraform output -raw dag_gcs_prefix)

# Upload DAGs
gsutil cp your_dag.py $DAG_BUCKET/
```

## Destroying the Environment

The KMS crypto key has `prevent_destroy = true`. To destroy all resources:

1. Remove the lifecycle block from `kms.tf`
2. Run `terraform apply` to update state
3. Run `terraform destroy`

> **Warning:** Deleting the KMS key makes all encrypted data permanently inaccessible.

## File Structure

```
├── versions.tf              # Provider and Terraform version constraints
├── variables.tf             # All input variables with validation
├── locals.tf                # Computed values, naming, labels, data sources
├── main.tf                  # API enablement
├── network.tf               # VPC, subnet, Cloud Router, Cloud NAT, firewalls
├── kms.tf                   # KMS keyring, crypto key, CMEK IAM bindings
├── iam.tf                   # Service account and IAM roles
├── composer.tf              # Cloud Composer 2 environment
├── outputs.tf               # Exported values
├── terraform.tfvars.example # Example variable values
└── .gitignore               # Terraform-specific ignores
```
