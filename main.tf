locals {
  fallback = var.fallback != null ? {
    filters = [
      "kind=${var.kind},metadata.namespace=${var.namespace},metadata.name=${var.name}",
    ]
    entities = [var.fallback]
  } : null
}

data "backstage_entities" "entity" {
  filters = [
    "kind=${var.kind},metadata.namespace=${var.namespace},metadata.name=${var.name}",
  ]
  fallback = local.fallback
}
