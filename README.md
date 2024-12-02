# terraform-backstage-metadata-module

[![⚙️ CI](https://github.com/Silthus/terraform-backstage-metadata-module/actions/workflows/ci.yaml/badge.svg)](https://github.com/Silthus/terraform-backstage-metadata-module/actions/workflows/ci.yaml)
[![🚀 Release Please](https://github.com/Silthus/terraform-backstage-metadata-module/actions/workflows/release.yaml/badge.svg)](https://github.com/Silthus/terraform-backstage-metadata-module/actions/workflows/release.yaml)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/silthus/terraform-backstage-metadata-module)](https://github.com/Silthus/terraform-backstage-metadata-module/releases)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--versioning-e10079.svg)](https://semver.org/)
[![GitHub License](https://img.shields.io/github/license/silthus/terraform-backstage-metadata-module)](https://github.com/Silthus/terraform-backstage-metadata-module/blob/main/LICENSE)
[![GitHub Sponsors](https://img.shields.io/github/sponsors/silthus)](https://github.com/sponsors/Silthus)

A metadata wrapper module around the [Terraform Backstage provider](https://registry.terraform.io/providers/datolabs-io/backstage/latest) to fetch metadata for an entity from Backstage and compile a list of resource labels as output.

## Features

- Fetch metadata for a Backstage entity
- Compile a list of resource labels from the metadata
- Fallback to a provided metadata object if the Backstage API is not reachable
- Retry the request to the Backstage API a configurable number of times

## Fallback Mechanism

In general, tying infrastructure to a third-party API is not recommended. However, in some cases, it is necessary to fetch metadata from a third-party API to configure infrastructure. In such cases, it is important to have a fallback mechanism in place to ensure that the infrastructure can still be configured even if the third-party API is not reachable.

This module provides multiple fallback mechanisms ensuring that the infrastructure can still be configured even if the Backstage API is not reachable.

### Retry API Requests

If configured the [datolabs-io/backstage](https://registry.terraform.io/providers/datolabs-io/backstage/latest) provider will retry the request to the Backstage API a configurable number of times before failing. This ensures that the request is retried multiple times before falling back to the next fallback mechanism.

```hcl
provider "backstage" {
  ...
  # After failing the `fallback` input of the module kicks in.
  retries = 3
}
```

### Remote State Fallback

If the `fallback` input is provided, the module will use the provided metadata object as a fallback if the Backstage API is not reachable. This allows you to provide a known good metadata object as a fallback in case the Backstage API is not reachable.  
It is recommended to use the [`terraform_remote_state`](https://developer.hashicorp.com/terraform/language/state/remote-state-data) data source to fetch the last known metadata object from the remote state backend.

```hcl
module "metadata" {
  source = "github.com/silthus/terraform-backstage-metadata-module?ref=v1.0.0" # x-release-please-version

  name = var.entity_name
  # This loops back the last metadata in the state
  # as a fallback if the Backstage API is not reachable.
  # By design the terraform_remote_state data source will return null if no state is found.
  # And the metadata module will simply treat a null fallback as no fallback, and will return an error if the Backstage API is not reachable.
  fallback = data.terraform_remote_state.metadata.outputs.metadata.entity
}

data "terraform_remote_state" "metadata" {
  backend = "gcs" // TODO: replace this with the actual backend and config you are using
  config = {
    bucket = "some-bucket"
    prefix = "some-prefix"
  }
}
```

### Fallback Sub-Module

As a last resort, or if you don't want to use the remote state fallback, you can manually switch the `modules/fallback` submodule, which acks as a mock Backstage API and returns a predefined object with empty and dummy labels and metadata.

```hcl
module "metadata" {
  source = "github.com/silthus/terraform-backstage-metadata-module//modules/fallback?ref=v1.0.0" # x-release-please-version

  name = var.entity_name
}
```

<!-- BEGIN_TF_DOCS -->


## Usage

```hcl
module "metadata" {
  source = "github.com/silthus/terraform-backstage-metadata-module?ref=v1.0.0" # x-release-please-version

  name = var.entity_name
  # This loops back the last metadata in the state
  # as a fallback if the Backstage API is not reachable.
  # By design the terraform_remote_state data source will return null if no state is found.
  # And the metadata module will simply treat a null fallback as no fallback, and will return an error if the Backstage API is not reachable.
  fallback = data.terraform_remote_state.metadata.outputs.metadata.entity
}

data "terraform_remote_state" "metadata" {
  backend = "gcs" // TODO: replace this with the actual backend and config you are using
  config = {
    bucket = "some-bucket"
    prefix = "some-prefix"
  }
}

provider "backstage" {
  base_url = "https://backstage.io/" # TODO: provide your own Backstage URL
  headers = {
    "Authorization" = "Bearer <some-token>" # TODO: provide your own Backstage API token. See https://backstage.io/docs/auth/service-to-service-auth/#static-tokens for more information.
  }
  # This configures the fallback capabilities of the provider itself to retry the request 3 times before failing.
  # After failing the above `fallback` kicks in and provides the last known metadata from the terraform state.
  retries = 3
}
```

## Required Inputs

The following input variables are required:

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the entity you need metadata for.

Type: `string`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_environment"></a> [environment](#input\_environment)

Description: The name of the environment you are deploying to.

Type: `string`

Default: `"unknown"`

### <a name="input_fallback"></a> [fallback](#input\_fallback)

Description: The fallback data to use if the Backstage API returns an error or is not reachable. It is recommended to use the terraform\_remote\_state data source to fetch the data from the remote state backend.

Type:

```hcl
object({
    api_version = string
    kind        = string
    metadata = object({
      annotations = optional(map(string))
      description = optional(string)
      etag        = optional(string)
      labels      = optional(map(string))
      links = optional(list(object({
        icon  = optional(string)
        title = string
        type  = optional(string)
        url   = string
      })))
      name      = string
      namespace = string
      tags      = optional(list(string))
      title     = optional(string)
    })
    relations = optional(list(object({
      target = object({
        kind      = string
        name      = string
        namespace = string
      })
      target_ref = string
      type       = string
    })))
    spec = optional(string)
  })
```

Default: `null`

### <a name="input_kind"></a> [kind](#input\_kind)

Description: The kind of Backstage entity you are fetch metadata for.

Type: `string`

Default: `"Component"`

### <a name="input_namespace"></a> [namespace](#input\_namespace)

Description: The namespace of the entity you need metadata for.

Type: `string`

Default: `"default"`

## Outputs

The following outputs are exported:

### <a name="output_entity"></a> [entity](#output\_entity)

Description: The full component object as defined by the Backstage API.

### <a name="output_labels"></a> [labels](#output\_labels)

Description: A common set of labels to attach to cloud resources.

### <a name="output_metadata"></a> [metadata](#output\_metadata)

Description: A flattened filtered set of metadata from the component object.

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9.6, < 2)

- <a name="requirement_backstage"></a> [backstage](#requirement\_backstage) (>= 3.1.0)

## Providers

The following providers are used by this module:

- <a name="provider_backstage"></a> [backstage](#provider\_backstage) (3.1.0)

## Modules

No modules.

## Resources

The following resources are used by this module:

- [backstage_entities.entity](https://registry.terraform.io/providers/datolabs-io/backstage/latest/docs/data-sources/entities) (data source)
<!-- END_TF_DOCS -->