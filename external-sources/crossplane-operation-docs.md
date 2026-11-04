---
author: Crossplane project (CNCF), docs CC-BY-4.0
date_fetched: 2026-11-04
description: "Operation detail page: run-once function pipelines for operational tasks; retry behavior, credentials, required resources, render CLI, best practices."
media_type: text/html
preservation: text-extracted
source_url: https://docs.crossplane.io/latest/operations/operation/
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - crossplane
title: Operation (Crossplane docs v2.4)
type: source
---
# Operation · Crossplane v2.4 docs (fetched 2026-11-04)

> Note: partial capture — web fetcher truncated the middle (status/pipeline output fields detail). The head (how operations work, key characteristics, composition-vs-operation functions, use cases, retry, credentials, multi-step pipelines, RBAC) and tail (render CLI, best practices, next steps) are captured verbatim. Nav boilerplate trimmed.

This is an alpha feature. Crossplane may change or drop this feature at any time.

This feature was introduced in v2.

An `Operation` runs a function pipeline once to completion to perform operational tasks that don't fit the typical resource creation pattern. Unlike compositions that continuously reconcile desired state, Operations focus on tasks like backups, rolling upgrades, configuration validation, and scheduled maintenance.

## How operations work

Operations are like Kubernetes Jobs - they run once to completion rather than continuously reconciling. Like compositions, Operations use function pipelines to implement their logic, but they're designed for operational workflows instead of resource composition.

```yaml
apiVersion: ops.crossplane.io/v1alpha1
kind: Operation
metadata:
  name: backup-database
spec:
  mode: Pipeline
  pipeline:
  - step: create-backup
    functionRef:
      name: function-database-backup
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: DatabaseBackupInput
      database: production-db
      retentionDays: 30
```

When you create this Operation, Crossplane:

1. Validates the operation and its function dependencies
2. Executes the function pipeline step by step
3. Applies any resources the functions create or change
4. Updates the Operation status with results and completion state

Important: Operations are an alpha feature. You must enable them by adding `--enable-operations` to Crossplane's arguments.

## Key characteristics

- Runs once to completion (like Kubernetes Jobs)
- Uses function pipelines (like Compositions)
- Can create or change any Kubernetes resources
- Provides detailed status and output from each step
- Supports retry on failure with configurable limits

## Operation functions vs composition functions

Operations and compositions both use function pipelines, but with important differences:

Composition Functions:

- Purpose: Create and maintain resources
- Lifecycle: Continuous reconciliation
- Input: Observed composite resources
- Output: Desired composed resources
- Ownership: Creates owner references

Operation Functions:

- Purpose: Perform operational tasks
- Lifecycle: Run once to completion
- Input: Required resources only
- Output: Any Kubernetes resources
- Ownership: Force applies without owners

Functions can support both modes by declaring the appropriate capabilities in their package metadata. Function authors declare this in the `crossplane.yaml` file when building the function package:

```yaml
apiVersion: meta.pkg.crossplane.io/v1
kind: Function
metadata:
  name: my-function
spec:
  capabilities:
  - composition
  - operation
```

This allows Crossplane to know which modes the function supports and avoid trying to use a composition-only function for operations.

## Common use cases

Note: The following examples use hypothetical functions for illustration. At launch, only function-python supports operations.

### Rolling upgrades

Use Operations for controlled rolling upgrades:

```yaml
apiVersion: ops.crossplane.io/v1alpha1
kind: Operation
metadata:
  name: cluster-upgrade
spec:
  mode: Pipeline
  pipeline:
  - step: rolling-upgrade
    functionRef:
      name: function-cluster-upgrade
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: ClusterUpgradeInput
      targetVersion: "1.28"
      batches: [0.25, 0.5, 1.0]  # 25%, 50%, then 100%
      healthChecks: [Synced, Ready]
```

### One-time maintenance

Use Operations for specific maintenance tasks:

```yaml
apiVersion: ops.crossplane.io/v1alpha1
kind: Operation
metadata:
  name: certificate-rotation
spec:
  mode: Pipeline
  pipeline:
  - step: rotate-certificates
    functionRef:
      name: function-cert-rotation
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: CertRotationInput
      targetCertificates:
        matchLabels:
          rotate: "true"
```

## Advanced configuration

### Retry behavior

Operations automatically retry when they fail. Configure the retry limit to control how often attempts occur:

```yaml
apiVersion: ops.crossplane.io/v1alpha1
kind: Operation
metadata:
  name: resilient-operation
spec:
  retryLimit: 10  # Try up to 10 times before giving up (default: 5)
  mode: Pipeline
  pipeline:
  - step: flaky-task
    functionRef:
      name: function-flaky-task
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: FlakyTaskInput
      timeout: "30s"
```

Retry behavior:

- Each retry resets the entire pipeline - if step 2 of 3 fails, the retry starts from step 1
- Operations use exponential backoff: 1 s, 2 s, 4 s, 8 s, 16 s, 32 s, then 60 s max
- Operations track the number of failures in `status.failures`
- After reaching `retryLimit`, the Operation becomes `Succeeded=False`

### Credentials

Operations can provide credentials to functions through Secrets:

```yaml
apiVersion: ops.crossplane.io/v1alpha1
kind: Operation
metadata:
  name: secure-backup
spec:
  mode: Pipeline
  pipeline:
  - step: backup-with-credentials
    functionRef:
      name: function-backup
    credentials:
    - name: backup-creds
      source: Secret
      secretRef:
        namespace: crossplane-system
        name: backup-credentials
        key: api-key
    - name: database-creds
      source: Secret
      secretRef:
        namespace: crossplane-system
        name: database-credentials
        key: connection-string
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: BackupInput
      destination: s3://my-backup-bucket
```

### Multiple pipeline steps

Complex operations can use multiple pipeline steps:

```yaml
apiVersion: ops.crossplane.io/v1alpha1
kind: Operation
metadata:
  name: multi-step-deployment
spec:
  mode: Pipeline
  pipeline:
  - step: validate-config
    functionRef:
      name: function-validator
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: ValidatorInput
      configName: app-config
  - step: backup-current
    functionRef:
      name: function-backup
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: BackupInput
      target: current-deployment
  - step: deploy-new-version
    functionRef:
      name: function-deploy
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: DeployInput
      image: myapp:v2.0.0
      strategy: rollingUpdate
  - step: verify-health
    functionRef:
      name: function-health-check
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: HealthCheckInput
      timeout: 300s
      healthEndpoint: /health
```

If your Operation needs to access resources that Crossplane doesn't have permissions for by default, create a ClusterRole that aggregates to Crossplane:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: operation-additional-permissions
  labels:
    rbac.crossplane.io/aggregate-to-crossplane: "true"
rules:
- apiGroups: ["networking.k8s.io"]
  resources: ["ingresses"]
  verbs: ["get", "list", "patch", "update"]
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get", "list"]
```

This ClusterRole is automatically aggregated to Crossplane's main ClusterRole, giving the Crossplane service account the permissions needed for your Operations.

Note: The RBAC manager automatically grants Crossplane access to Crossplane resources (MRs, XRs, etc.). You only need to create more ClusterRoles for other Kubernetes resources that your Operations need to access.

### Function response cache

Note: Function response caching is an alpha feature. Enable it by setting the `--enable-function-response-cache` feature flag.

Operations can use function response caching to improve performance for operations that:

- Call the same functions often with identical inputs
- Use functions that perform expensive computations or external API calls
- Run frequently through CronOperation or WatchOperation

The cache works the same way as for Compositions - function responses with time to live values cache and reuse identical requests until they expire.

### Required resources

Operations can preload resources for functions to access:

```yaml
apiVersion: ops.crossplane.io/v1alpha1
kind: Operation
metadata:
  name: resource-aware-operation
spec:
  mode: Pipeline
  pipeline:
  - step: process-deployment
    functionRef:
      name: function-processor
    requirements:
      requiredResources:
      - requirementName: app-deployment
        apiVersion: apps/v1
        kind: Deployment
        name: my-app
        namespace: production
      - requirementName: app-service
        apiVersion: v1
        kind: Service
        name: my-app-service
        namespace: production
    input:
      apiVersion: fn.crossplane.io/v1beta1
      kind: ProcessorInput
      action: upgrade
```

Functions access these resources through the standard request structure:

```python
from crossplane.function import request, response

def operate(req, rsp):
    deployment = request.get_required_resource(req, "app-deployment")
    service = request.get_required_resource(req, "app-service")

    if not deployment or not service:
        response.set_output(rsp, {"error": "Required resources not found"})
        return

    new_replicas = deployment["spec"]["replicas"] * 2

    rsp.desired.resources["app-deployment"].resource.update({
        "apiVersion": "apps/v1",
        "kind": "Deployment",
        "metadata": {
            "name": deployment["metadata"]["name"],
            "namespace": deployment["metadata"]["namespace"]
        },
        "spec": {"replicas": new_replicas}
    })
```

[... middle omitted — status conditions and pipeline output detail ...]

## Test an operation

You can preview the output of any Operation using the Crossplane CLI. You don't need a Crossplane control plane to do this. The Crossplane CLI uses Docker Engine to run functions.

Important: The CLI hides alpha commands, including `crossplane operation render`, by default. Run `crossplane config set features.enableAlpha true` to make it visible.

Important: Running `crossplane operation render` requires Docker.

Provide an operation, composition functions, and any required resources to render the output locally.

```shell
crossplane operation render operation.yaml functions.yaml --required-resources=ingress.yaml
```

`crossplane operation render` prints the Operation status and any resources the operation functions created or modified. It shows what would happen if you applied the Operation to a cluster.

```yaml
---
apiVersion: ops.crossplane.io/v1alpha1
kind: Operation
metadata:
  name: ingress-cert-monitor
status:
  conditions:
  - type: Succeeded
    status: "True"
    reason: PipelineSuccess
  pipeline:
  - step: check-ingress-certificate
    output:
      certificateExpires: "Sep 29 08:34:02 2025 GMT"
      daysUntilExpiry: 53
      hostname: google.com
      ingressName: example-app
      status: ok
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-monitor.crossplane.io/expires: Sep 29 08:34:02 2025 GMT
    cert-monitor.crossplane.io/days-until-expiry: "53"
    cert-monitor.crossplane.io/status: ok
  name: example-app
  namespace: default
spec:
  # ... ingress spec unchanged
```

Use `--required-resources` to provide resources that your operation functions need access to. You can specify multiple files or use glob patterns.

Tip: Use the `crossplane operation render` command to test your Operations locally before deploying them to a cluster.

## Best practices

### Operation-specific practices

1. Plan for rollback - Design operations to be reversible when possible, because Operations don't auto rollback like Compositions
2. Make operations idempotent - Operations should be safe to retry if they fail partway through
3. Use required resources - Prepopulate functions with needed resources for efficiency rather than requesting them during running

### Function development

1. Declare capabilities - Explicitly declare `operation` capability in function metadata to enable Operations support
2. Return meaningful output - Use the output field to track what the operation accomplished for monitoring and debugging

## Next steps

- Get started with Operations to create your first Operation
- Learn about CronOperation for scheduled operations
- Learn about WatchOperation for reactive operations
