terraform {
  required_version = ">= 1.5.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "2.1.0"
    }
    cloudvps = {
      source  = "terraform.wmcloud.org/registry/cloudvps"
      version = "~> 0.2.0"
    }
  }
}

resource "openstack_compute_instance_v2" "quickstart_ci_instance" {
  name            = "quickstart-ci-components"
  image_name      = "debian-12.0-bookworm"
  flavor_name     = "g4.cores2.ram4.disk20"
  security_groups = ["default"]
  network {
    name = "VLAN/legacy"
  }
  user_data = file("${path.module}/vps.cloudconfig.yml")
  lifecycle {
    ignore_changes = [user_data]
  }
}

# Create volume
resource "openstack_blockstorage_volume_v3" "quickstart_storage" {
  name        = "quickstart-ci-storage"
  description = "Additional storage for CI components instance"
  size        = 80  # GB
}

# Attach volume to instance
resource "openstack_compute_volume_attach_v2" "quickstart_storage_attachment" {
  instance_id = openstack_compute_instance_v2.quickstart_ci_instance.id
  volume_id   = openstack_blockstorage_volume_v3.quickstart_storage.id
}

output "instance_ip" {
  value = openstack_compute_instance_v2.quickstart_ci_instance.access_ip_v4
}

output "volume_device" {
  value       = openstack_compute_volume_attach_v2.quickstart_storage_attachment.device
  description = "Device path where volume is attached (e.g., /dev/vdb)"
}

# Configure cloudvps for Web Proxy entry
variable "os_auth_url" {}
variable "os_application_credential_id" {}
variable "os_application_credential_secret" {}
variable "os_project_id" {}

provider "cloudvps" {
  os_auth_url                     = var.os_auth_url
  os_application_credential_id    = var.os_application_credential_id
  os_application_credential_secret = var.os_application_credential_secret
  os_project_id                   = var.os_project_id
}

resource "cloudvps_web_proxy" "quickstart_ci" {
  hostname = "quickstart-ci-components"
  backends = ["http://${openstack_compute_instance_v2.quickstart_ci_instance.access_ip_v4}:8088"]
  domain   = "wmcloud.org"
}
