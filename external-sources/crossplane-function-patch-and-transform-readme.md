---
author: crossplane-contrib
date_fetched: 2026-11-04
description: Composition function that re-implements Crossplane's native patch-and-transform as a pipeline step; mix-and-match with other functions; decoupled from core release cycle.
media_type: text/markdown
preservation: text-extracted
source_url: https://raw.githubusercontent.com/crossplane-contrib/function-patch-and-transform/main/README.md
tags:
  - source
  - immutable
  - layer-ingest
  - text
  - crossplane
title: function-patch-and-transform README (crossplane-contrib, main)
type: source
---
# function-patch-and-transform README (main, fetched 2026-11-04)

> Note: partial capture — web fetcher truncated the middle (forking guidance, examples index). The head (purpose, YAML example, why-use-a-function rationale) and the mix-and-match section are captured verbatim. Badge markup trimmed.

This composition function does everything Crossplane's built-in patch & transform (P&T) composition does. Instead of specifying `spec.resources` in your Composition, you can use this function.

Using this function, P&T looks like this:

```yaml
apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
  name: example
spec:
  # Omitted for brevity.
  mode: Pipeline
  pipeline:
  - step: patch-and-transform
    functionRef:
      name: function-patch-and-transform
    input:
      apiVersion: pt.fn.crossplane.io/v1beta1
      kind: Resources
      resources:
      - name: bucket
        base:
          apiVersion: s3.aws.upbound.io/v1beta1
          kind: Bucket
          spec:
            forProvider:
              region: us-east-2
        patches:
        - type: FromCompositeFieldPath
          fromFieldPath: "spec.location"
          toFieldPath: "spec.forProvider.region"
          transforms:
          - type: map
            map:
              EU: "eu-north-1"
              US: "us-east-2"
```

Notice that it looks very similar to native P&T. The difference is that everything is under `spec.pipeline[0].input.resources`, not `spec.resources`. This is the Function's input.

## Okay, but why?

There are a lot of good reasons to use a function to do P&T composition. In fact, it's so compelling that the Crossplane maintainers are considering deprecating native P&T. See Crossplane issue #4746 for details.

### Mix and match P&T with other functions

With this function you can use P&T with other functions. For example you can create a desired resource using the Go Templating function, then patch the result using this function.

To include results from previous functions, simply provide a `resources` entry for each and specify a `name` field that matches the name of the resource from the previous function. Also, do not specify any value for the `base` field of each resource.

It's not just patches either. You can use P&T to derive composite resource connection details from a resource produced by another function, or use it to determine whether a resource produced by another function is ready.

A straightforward example for multistep mix and match pipeline with function-patch-and-transform and function-go-templating can be found in the repo's example/multistep directory.

### Decouple P&T development from Crossplane core

When P&T development happens in a function, it's not coupled to the Crossplane release cycle. The maintainers of this function can cut releases more frequently to add new features to P&T.

It also becomes easier to fork. You could fork this function to add your own features without waiting for the Crossplane maintainers to review and merge them.
