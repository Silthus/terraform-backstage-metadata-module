globals "terraform" "providers" "backstage" {
  source  = "datolabs-io/backstage"
  version = "~> 3.1.0"
  enabled = true
}

generate_hcl "_terramate_generated_backstage_provider.tf" {
  condition = tm_try(global.terraform.providers.backstage.enabled, false) && tm_try(global.metadata_module.enabled, false)

  lets {
    using_secret_manager = tm_try(global.terraform.providers.backstage.config.api_key_secret_id, null) != null
  }

  content {
    tm_dynamic "data" {
      labels    = ["google_secret_manager_secret_version_access", "fallback"]
      condition = tm_can(global.terraform.providers.backstage.config.api_key_secret_id)

      content {
        project = tm_try(global.terraform.providers.backstage.config.api_key_secret_project, null)
        secret  = tm_try(global.terraform.providers.backstage.config.api_key_secret_id, null)
        version = tm_try(global.terraform.providers.backstage.config.api_key_secret_version, "latest")
      }
    }

    locals {
      headers = tm_try(global.terraform.providers.backstage.config.headers, null)
    }

    tm_dynamic "provider" {
      labels = ["backstage"]

      content {
        base_url = tm_try(global.terraform.providers.backstage.config.base_url, null)
        retries  = tm_try(global.terraform.providers.backstage.config.retries, 3)
        headers = local.headers != null ? local.headers : {
          "Authorization" = "Bearer ${tm_ternary(let.using_secret_manager,
            tm_hcl_expression("data.google_secret_manager_secret_version_access.fallback.secret_data"),
            tm_try(global.terraform.providers.backstage.config.api_key, null)
          )}"
        }
      }
    }
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
    assertion = tm_length(tm_compact([
      tm_try(global.terraform.providers.backstage.config.api_key_secret_id, null) != null ? "api_key_secret_id" : null,
      tm_try(global.terraform.providers.backstage.config.api_key, null) != null ? "api_key" : null,
      tm_try(global.terraform.providers.backstage.config.headers, null) != null ? "headers" : null
    ])) <= 1
    message = "Multiple authentication methods configured for Backstage provider. Please use only one of: 'api_key_secret_id', 'api_key', or 'headers'"
    warning = true
  }
}