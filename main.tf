terraform {
  required_version = ">= 0.14"
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
    }
  }
}

provider "openstack" {
  cloud = "openstack"
}

data "openstack_networking_subnet_v2" "builder" {
    name =  "WCDC-iLab-60"
}

variable "name" {
    type = string
    default = "slurm_image_builder"
}

resource "openstack_networking_port_v2" "builder" {
    
    name = var.name
    network_id = data.openstack_networking_subnet_v2.builder.network_id
    fixed_ip {
        subnet_id = data.openstack_networking_subnet_v2.builder.id
    }
    security_group_ids = [
        "bd9d0a1e-1127-4910-9fb0-232d4dce2c2f", # default
        "486dfc85-099b-4bbb-9375-60f320a7de18", # SSH
    ]
    admin_state_up = "true"
    binding {
        vnic_type = "direct"
    }
}

output "port_id" {
    value = openstack_networking_port_v2.builder.id
}
