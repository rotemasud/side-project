# ECR ImagePullSecret Management

This module automatically creates and manages Kubernetes imagePullSecrets for pulling images from private AWS ECR repositories.

## Overview

The ECR secret management system consists of:

1. **IRSA Role** - IAM role for service accounts with ECR read permissions
2. **Kubernetes ServiceAccount** - ServiceAccount with IRSA annotation for the CronJob
3. **RBAC Resources** - Role and RoleBinding to allow secret management in the target namespace
4. **CronJob** - Runs every 10 hours to refresh the ECR token (tokens expire after 12 hours)
5. **Initial Secret** - Creates the initial secret via Terraform local-exec provisioner

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        ECR Token Flow                        │
└─────────────────────────────────────────────────────────────┘

1. Terraform creates initial secret during apply
2. CronJob runs every 10 hours (before 12-hour token expiration)
3. CronJob uses IRSA to authenticate with AWS
4. Gets fresh ECR token from AWS ECR API
5. Deletes old secret and creates new one
6. Pods reference the secret for image pulling
```

## Usage

### Enable in your Terraform

In your root `main.tf`:

```hcl
module "eks_tools" {
  source = "./modules/eks-tools"
  
  # ... other configuration ...
  
  # ECR ImagePullSecret
  ecr_secret_enabled    = true
  ecr_secret_namespace  = "runtime"      # Namespace for your app
  ecr_secret_name       = "ecr-registry-secret"
  ecr_create_namespace  = true
  ecr_repository_arns   = [module.ecr.aws_ecr_repository_arn]
}
```

### Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ecr_secret_enabled` | bool | `false` | Enable ECR secret management |
| `ecr_secret_namespace` | string | `"runtime"` | Target namespace for the secret |
| `ecr_secret_name` | string | `"ecr-registry-secret"` | Name of the secret |
| `ecr_create_namespace` | bool | `true` | Create namespace if it doesn't exist |
| `ecr_repository_arns` | list(string) | `[]` | ECR repository ARNs to grant access to |

### Using in Helm Charts

Reference the secret in your `values.yaml`:

```yaml
imagePullSecrets:
  - name: ecr-registry-secret
```

Or in your Pod spec:

```yaml
spec:
  imagePullSecrets:
    - name: ecr-registry-secret
  containers:
    - name: my-app
      image: ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/my-repo:tag
```

## Resources Created

### AWS IAM Resources

- **IAM Role**: `eks-ecr-token-renew-<cluster-name>`
  - Trust policy for OIDC provider
  - Permissions for ECR read operations

### Kubernetes Resources

- **Namespace**: `<ecr_secret_namespace>` (if `ecr_create_namespace` is true)
- **ServiceAccount**: `ecr-renew-sa` (in `kube-system` namespace)
- **Role**: `ecr-renew-role` (in target namespace)
- **RoleBinding**: `ecr-renew-rolebinding` (in target namespace)
- **CronJob**: `ecr-secret-renewal` (in `kube-system` namespace)
- **Secret**: `<ecr_secret_name>` (in target namespace)

## How It Works

### Initial Secret Creation

When you run `terraform apply`, the `null_resource.ecr_secret_initial` provisioner:

1. Gets an ECR authentication token using AWS CLI
2. Creates a Docker config JSON with the token
3. Creates a Kubernetes secret of type `kubernetes.io/dockerconfigjson`

### Automatic Renewal

The CronJob runs every 10 hours and:

1. Uses IRSA to authenticate with AWS (no credentials needed in cluster)
2. Calls `aws ecr get-login-password` to get a fresh token
3. Deletes the old secret
4. Creates a new secret with the fresh token

### Token Expiration

- ECR tokens expire after **12 hours**
- CronJob runs every **10 hours** (2-hour safety margin)
- If a job fails, Kubernetes will retry

## Monitoring

### Check CronJob Status

```bash
# View the CronJob
kubectl get cronjob ecr-secret-renewal -n kube-system

# View recent jobs
kubectl get jobs -n kube-system | grep ecr-secret

# View job logs
kubectl logs -n kube-system job/<job-name>
```

### Check Secret

```bash
# View the secret
kubectl get secret ecr-registry-secret -n runtime

# Decode and inspect (for debugging)
kubectl get secret ecr-registry-secret -n runtime -o jsonpath='{.data.\.dockerconfigjson}' | base64 -d | jq
```

### Check IAM Role

```bash
# View the role annotation on ServiceAccount
kubectl get sa ecr-renew-sa -n kube-system -o yaml

# Check IRSA setup
kubectl describe sa ecr-renew-sa -n kube-system
```

## Troubleshooting

### Secret Not Created

1. Check if CronJob exists:
   ```bash
   kubectl get cronjob -n kube-system
   ```

2. Check recent job logs:
   ```bash
   kubectl logs -n kube-system -l job-name --tail=50
   ```

3. Verify IRSA role:
   ```bash
   kubectl describe sa ecr-renew-sa -n kube-system
   ```

### Pods Can't Pull Images

1. Verify secret exists in correct namespace:
   ```bash
   kubectl get secret ecr-registry-secret -n <your-namespace>
   ```

2. Check pod events:
   ```bash
   kubectl describe pod <pod-name> -n <your-namespace>
   ```

3. Verify imagePullSecrets is set:
   ```bash
   kubectl get pod <pod-name> -n <your-namespace> -o jsonpath='{.spec.imagePullSecrets}'
   ```

### IRSA Not Working

1. Verify OIDC provider is configured correctly
2. Check IAM role trust policy includes correct OIDC provider
3. Ensure ServiceAccount annotation matches IAM role ARN
4. Check pod's service account token is mounted

## Security Considerations

- The IAM role uses IRSA (IAM Roles for Service Accounts) for secure authentication
- No AWS credentials are stored in the cluster
- The secret is namespace-scoped
- RBAC limits secret management to specific namespace
- ECR repository access is limited via IAM policy to specific repository ARNs

## Limitations

- Requires AWS CLI to be run during Terraform apply (for initial secret)
- CronJob requires internet access to ECR API
- Token renewal has a 2-hour window before expiration (should be sufficient for most cases)

## Alternative Approaches

If this solution doesn't fit your needs, consider:

1. **IRSA for application pods** - Give pods direct ECR access (no imagePullSecret needed)
2. **External Secrets Operator** - Manage secrets via external secret managers
3. **Sealed Secrets** - Encrypt secrets in Git
4. **Manual management** - Create/update secret manually as needed

