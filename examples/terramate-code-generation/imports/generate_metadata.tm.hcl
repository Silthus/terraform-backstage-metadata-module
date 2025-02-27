globals "metadata_module" {
  enabled               = tm_contains(terramate.stack.tags, "inject_metadata")
  remote_state_fallback = false

  source  = "github.com/Silthus/terraform-backstage-metadata-module.git"
  version = "v1.0.0"

  defaults = {
    entity_name      = terramate.stack.name
    entity_kind      = "Component"
    entity_namespace = "default"
  }
}

generate_hcl "_terramate_generated_metadata.tf" {
  condition = tm_try(global.metadata_module.enabled, false)

  lets {
    is_fallback_enabled = tm_alltrue([
      tm_try(global.metadata_module.remote_state_fallback, false),
      tm_can(global.terraform.backend.gcs.bucket),
      tm_can(global.terraform.backend.gcs.prefix)
    ])

    entity_name      = tm_try(global.metadata_module.entity_name, tm_try(global.metadata_module.defaults.entity_name, terramate.stack.name))
    entity_kind      = tm_try(global.metadata_module.entity_kind, tm_try(global.metadata_module.defaults.entity_kind, "Component"))
    entity_namespace = tm_try(global.metadata_module.entity_namespace, tm_try(global.metadata_module.defaults.entity_namespace, "default"))
  }

  content {
    variable "entity_name" {
      type        = string
      default     = let.entity_name
      description = "The name of the Backstage entity you are fetching metadata for. Override this variable by setting the Terraform variable in a `values.auto.tfvars` file or by setting the Terramate `globals.metadata_module.entity_name` variable."
    }

    variable "entity_kind" {
      type        = string
      default     = let.entity_kind
      description = "The kind (Component, System, API, etc.) of Backstage entity you are fetching metadata for. Override this variable by setting the Terraform variable in a `values.auto.tfvars` file or by setting the Terramate `globals.metadata_module.entity_kind` variable."
    }

    variable "entity_namespace" {
      type        = string
      default     = let.entity_namespace
      description = "The namespace of the Backstage entity you are fetching metadata for. Override this variable by setting the Terraform variable in a `values.auto.tfvars` file or by setting the Terramate `globals.metadata_module.entity_namespace` variable."
    }

    module "metadata" {
      source    = "${global.metadata_module.source}?ref=${global.metadata_module.version}"
      name      = var.entity_name
      kind      = var.entity_kind
      namespace = var.entity_namespace
      fallback  = tm_ternary(let.is_fallback_enabled, try(data.terraform_remote_state.fallback.outputs.metadata.entity, null), null)
    }

    tm_dynamic "data" {
      labels    = ["terraform_remote_state", "fallback"]
      condition = let.is_fallback_enabled
      content {
        backend = "gcs"
        config = {
          bucket = global.terraform.backend.gcs.bucket
          prefix = global.terraform.backend.gcs.prefix
        }
      }
    }
  }

  assert {
    assertion = !tm_try(global.metadata_module.remote_state_fallback, false) || tm_try(global.terraform.backend.gcs.bucket != null, false)
    message   = "Remote state fallback is enabled but 'global.terraform.backend.gcs.bucket' is not configured"
    warning   = true
  }

  assert {
    assertion = !tm_try(global.metadata_module.remote_state_fallback, false) || tm_try(global.terraform.backend.gcs.prefix != null, false)
    message   = "Remote state fallback is enabled but 'global.terraform.backend.gcs.prefix' is not configured"
    warning   = true
  }
}