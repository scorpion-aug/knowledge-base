---
date_fetched: 2026-11-04
preservation: text-extracted
media_type: text/html
author: Crossplane project (CNCF), docs CC-BY-4.0
description: "Managed resource concept page: forProvider as source of truth, cross-resource references (external name, nameRef, selector, controllerRef), immutable fields, late init, initProvider, managementPolicies, Upjet conditions."
title: Managed Resources (Crossplane docs v2.4)
type: source
source_url: https://docs.crossplane.io/latest/managed-resources/managed-resources/
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - crossplane
---
# Managed Resources · Crossplane v2.4 docs (fetched 2026-11-04)

> Note: partial capture — web fetcher truncated the middle (deletion policy, full managementPolicies table, all status conditions). The head (what MRs are, forProvider, cross-resource references, immutable fields, late initialization, initProvider, managementPolicies intro) and tail (Upjet async-operation conditions) are captured verbatim. Nav boilerplate trimmed.

A managed resource (MR) represents an external service in a Provider. When users create a new managed resource, the Provider reacts by creating an external resource inside the Provider's environment. Every external service managed by Crossplane maps to a managed resource.

Note: Crossplane calls the object inside Kubernetes a managed resource and the external object inside the Provider an external resource.

Examples of managed resources include:

- Amazon AWS EC2 `Instance` defined in provider-upjet-aws.
- Google Cloud GKE `Cluster` defined in provider-upjet-gcp.
- Microsoft Azure PostgreSQL `Database` defined in provider-upjet-azure.

## Managed resource fields

The Provider defines the group, kind and version of a managed resource. The Provider also define the available settings of a managed resource.

### Group, kind and version

Each managed resource is a unique API endpoint with their own group, kind and version.

For example the AWS Provider defines the `Instance` kind from the group `ec2.aws.m.upbound.io`.

```yaml
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: Instance
```

### forProvider

The `spec.forProvider` of a managed resource maps to the parameters of the external resource.

For example, when creating an AWS EC2 instance, the Provider supports defining the AWS `region` and the VM size, called the `instanceType`.

Note: The Provider defines the settings and their valid values. Providers also define required and optional values in the `forProvider` definition.

Important: Crossplane considers the `forProvider` field of a managed resource the "source of truth" for external resources. Crossplane overrides any changes made to an external resource outside of Crossplane. If a user makes a change inside a Provider's web console, Crossplane reverts that change back to what's configured in the `forProvider` setting.

#### Referencing other resources

Some fields in a managed resource may depend on values from other managed resources. For example a VM may need the name of a virtual network to use.

Managed resources can reference other managed resources by external name, name reference or selector.

##### Matching by external name

When matching a resource by name Crossplane looks for the name of the external resource in the Provider.

For example, a AWS VPC object named `my-test-vpc` has the external name `vpc-01353cfe93950a8ff`.

```shell
kubectl get vpc
NAME            READY   SYNCED   EXTERNAL-NAME           AGE
my-test-vpc     True    True     vpc-01353cfe93950a8ff   49m
```

To match the VPC by name, use the external name. For example, creating a Subnet managed resource attached to this VPC.

```yaml
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: Subnet
spec:
  forProvider:
    vpcId: vpc-01353cfe93950a8ff
```

##### Matching by name reference

To match a resource based on the name of the managed resource and not the external resource name inside the Provider, use a `nameRef`.

```yaml
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: Subnet
spec:
  forProvider:
    vpcIdRef:
      name: my-test-vpc
```

##### Matching by selector

Matching by selector is the most flexible matching method.

Use `matchLabels` to match the labels applied to a resource. For example, this Subnet resource only matches VPC resources with the label `my-label: label-value`.

```yaml
apiVersion: ec2.aws.m.upbound.io/v1beta1
kind: Subnet
spec:
  forProvider:
    vpcIdSelector:
      matchLabels:
        my-label: label-value
```

##### Matching by controller reference

Matching a controller reference ensures that the matching resource has the same Kubernetes controller reference.

Matching a controller reference is useful for matching a resource that's composed by the same composite resource (XR).

Using `matchControllerRef` matches only the VPC created in the same composite resource that created the `InternetGateway`.

#### Immutable fields

Some providers don't support changing the fields of some managed resources after creation. For example, you can't change the `region` of an Amazon AWS RDS `Instance`. These fields are immutable fields. Amazon requires you delete and recreate the resource.

Crossplane allows you to edit the immutable field of a managed resource, but doesn't apply the change. Crossplane never deletes a resource based on a `forProvider` change.

Note: Crossplane behaves differently than other tools like Terraform. Terraform deletes and recreates a resource to change an immutable field. Crossplane only deletes an external resource if you delete its corresponding managed resource object from Kubernetes.

#### Late initialization

Crossplane treats the managed resource as the source of truth by default; it expects to have all values under `spec.forProvider` including the optional ones. If not provided, Crossplane populates the empty fields with the values assigned by the provider. For example, consider fields such as `region` and `availabilityZone`. You might specify only the region and let the cloud provider choose the availability zone. In this case, if the provider assigns an availability zone, Crossplane uses that value to populate the `spec.forProvider.availabilityZone` field.

Note: With managementPolicies, this behavior can be turned off by not including the `LateInitialize` policy in the `managementPolicies` list.

### initProvider

Important: The managed resource `initProvider` option is a beta feature related to managementPolicies.

The `initProvider` defines settings Crossplane applies only when creating a new managed resource.

Crossplane ignores settings defined in the `initProvider` field that change after creation.

Note: Settings in `forProvider` are always enforced by Crossplane. Crossplane reverts any changes to a `forProvider` field in the external resource.

Settings in `initProvider` aren't enforced by Crossplane. Crossplane ignores any changes to a `initProvider` field in the external resource.

Using `initProvider` is useful for setting initial values that a Provider may automatically change, like an auto scaling group.

For example, creating a `NodeGroup` with an initial `desiredSize`.

Crossplane doesn't change the `desiredSize` setting back when an autoscaler scales the Node Group external resource.

Tip: Crossplane recommends configuring managementPolicies without `LateInitialize` to avoid conflicts with `initProvider` settings.

```yaml
apiVersion: eks.aws.m.upbound.io/v1beta1
kind: NodeGroup
metadata:
  namespace: default
  name: sample-eks-ng
spec:
  managementPolicies: ["Observe", "Create", "Update", "Delete"]
  initProvider:
    scalingConfig:
      desiredSize: 1
  forProvider:
    region: us-west-1
    clusterName: my-cluster
    scalingConfig:
      maxSize: 4
      minSize: 1
```

### managementPolicies

Note: The managed resource `managementPolicies` option is a beta feature. Crossplane enables beta features by default.

The Provider determines support for management policies. Refer to the Provider's documentation to see if the Provider supports management policies.

Crossplane `managementPolicies` determine which actions Crossplane can take on a managed resource and its corresponding external resource.

Apply one or more `managementPolicies` to a managed resource to determine what permissions Crossplane has over the resource.

[... middle omitted — full managementPolicies table (Observe/Create/Update/Delete/LateInitialize/*), deletion policy, and detailed status conditions ...]

### Upjet Provider conditions

Upjet, the open source tool to generate Crossplane Providers, also has a set of standard `Conditions`.

#### AsyncOperation

Some resources may take more than a minute to create. Upjet based providers can complete their Kubernetes command before creating the managed resource by using an asynchronous operation.

##### Finished

The `Reason: Finished` indicates the asynchronous operation completed successfully.

##### Ongoing

`Reason: Ongoing` indicates the managed resource operation is still in progress.

#### LastAsyncOperation

The Upjet `Type: LastAsyncOperation` captures the previous asynchronous operation status as either `Success` or a failure `Reason`.

##### ApplyFailure

`Reason: ApplyFailure` indicates the Provider failed to apply a setting to the managed resource. The `conditions.message` provides more information on what went wrong.

##### DestroyFailure

`Reason: DestroyFailure` indicates the Provider failed to delete the managed resource. The `conditions.message` provides more information on what went wrong.

##### Success

`Reason: Success` indicates the Provider successfully created the managed resource asynchronously.
