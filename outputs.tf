output "entity" {
  description = "The full component object as defined by the Backstage API."
  value       = data.backstage_entities.entity.entities[0]
  precondition {
    condition     = try(length(data.backstage_entities.entity.entities), 0) > 0
    error_message = "Entity '${lower(var.kind)}:${var.namespace}/${var.name}' not found in the Backstage catalog."
  }
}

output "metadata" {
  description = "A flattened filtered set of metadata from the component object."
  value = {
    entity      = var.name
    namespace   = var.namespace
    kind        = var.kind
    owner       = tostring(try(jsondecode(data.backstage_entities.entity.entities[0].spec)["owner"], null))
    system      = tostring(try(jsondecode(data.backstage_entities.entity.entities[0].spec)["system"], null))
    lifecycle   = tostring(try(jsondecode(data.backstage_entities.entity.entities[0].spec)["lifecycle"], null))
    type        = tostring(try(jsondecode(data.backstage_entities.entity.entities[0].spec)["type"], null))
    environment = var.environment
  }
  precondition {
    condition     = try(length(data.backstage_entities.entity.entities), 0) > 0
    error_message = "Entity '${lower(var.kind)}:${var.namespace}/${var.name}' not found in the Backstage catalog."
  }
}

output "labels" {
  description = "A common set of labels to attach to cloud resources."
  value = {
    "created-by"      = "terraform"
    "entity"          = lower(var.name)
    (lower(var.kind)) = lower(var.name)
    "kind"            = lower(var.kind)
    "owner"           = tostring(try(lower(jsondecode(data.backstage_entities.entity.entities[0].spec)["owner"]), null))
    "system"          = tostring(try(lower(jsondecode(data.backstage_entities.entity.entities[0].spec)["system"]), null))
    "lifecycle"       = tostring(try(lower(jsondecode(data.backstage_entities.entity.entities[0].spec)["lifecycle"]), null))
    "type"            = tostring(try(lower(jsondecode(data.backstage_entities.entity.entities[0].spec)["type"]), null))
    "environment"     = lower(var.environment)
  }
  precondition {
    condition     = try(length(data.backstage_entities.entity.entities), 0) > 0
    error_message = "Entity '${lower(var.kind)}:${var.namespace}/${var.name}' not found in the Backstage catalog."
  }
}
