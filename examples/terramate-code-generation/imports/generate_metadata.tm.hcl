globals "metadata_module" {
  enabled               = false
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
  condition = let.is_metadata_module_enabled

  lets {
    bucket_name   = tm_try(global.terraform.backend.gcs.bucket, null)
    bucket_prefix = tm_try(global.terraform.backend.gcs.prefix, null)

    is_backstage_provider_configured = tm_alltrue([
      tm_try(global.terraform.providers.backstage.enabled, false),
      tm_can(global.terraform.providers.backstage.config.base_url),
      tm_anytrue([
        tm_can(global.terraform.providers.backstage.config.api_key_secret_id),
        tm_can(global.terraform.providers.backstage.config.api_key),
        tm_can(global.terraform.providers.backstage.config.headers)
      ])
    ])

    is_metadata_module_enabled = tm_alltrue([
      tm_try(global.terraform.providers.backstage.enabled, false),
      tm_anytrue([
        # Allow stack tags-based configuration
        tm_contains(terramate.stack.tags, "inject_metadata"),
        # Allow config-sharing based configuration
        tm_try(global.metadata_module.enabled == true, false)
      ])
    ])

    is_fallback_enabled = tm_alltrue([
      let.is_backstage_provider_configured,
      tm_try(global.metadata_module.remote_state_fallback, false),
      tm_can(let.bucket_name),
      tm_can(let.bucket_prefix)
    ])

    entity_name      = tm_try(global.metadata_module.entity_name, tm_try(global.metadata_module.defaults.entity_name, terramate.stack.name))
    entity_kind      = tm_try(global.metadata_module.entity_kind, tm_try(global.metadata_module.defaults.entity_kind, "Component"))
    entity_namespace = tm_try(global.metadata_module.entity_namespace, tm_try(global.metadata_module.defaults.entity_namespace, "default"))
  }

  assert {
    assertion = tm_try(global.terraform.providers.backstage.config.base_url, null) != null
    message   = "Backstage provider is enabled but 'global.terraform.providers.backstage.config.base_url' is not configured"
  }

  assert {
    assertion = tm_anytrue([
      tm_try(global.terraform.providers.backstage.config.api_key_secret_id != null, false),
      tm_try(global.terraform.providers.backstage.config.api_key != null, false),
      tm_try(global.terraform.providers.backstage.config.headers != null, false)
    ])
    message = "Backstage provider is enabled but no authentication method is configured. Set either 'api_key_secret_id', 'api_key', or 'headers'"
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

  content {
    tm_dynamic "data" {
      labels    = ["google_secret_manager_secret_version_access", "fallback"]
      condition = tm_try(global.terraform.providers.backstage.config.api_key_secret_id, false)

      content {
        project = tm_try(global.terraform.providers.backstage.config.api_key_secret_project, null)
        secret  = tm_try(global.terraform.providers.backstage.config.api_key_secret_id, null)
        version = tm_try(global.terraform.providers.backstage.config.api_key_secret_version, "latest")
      }
    }

    tm_dynamic "provider" {
      labels    = ["backstage"]
      condition = let.is_backstage_provider_configured

      content {
        base_url = tm_try(global.terraform.providers.backstage.config.base_url, null)
        retries  = tm_try(global.terraform.providers.backstage.config.retries, 3)
        headers = tm_try(global.terraform.providers.backstage.config.headers, {
          "Authorization" = "Bearer ${tm_try(data.google_secret_manager_secret_version_access.backstage_api_key.secret_data, tm_try(global.terraform.providers.backstage.config.api_key, null))}"
        })
      }
    }

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
          bucket = let.bucket_name
          prefix = let.bucket_prefix
        }
      }
    }
  }
}