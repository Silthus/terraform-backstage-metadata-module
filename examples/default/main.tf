module "metadata" {
  source = "github.com/silthus/terraform-backstage-metadata-module?ref=v0.1.0" # x-release-please-version

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
