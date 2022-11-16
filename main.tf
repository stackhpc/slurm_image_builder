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

data "openstack_networking_secgroup_v2" "default" {
  name = "default"
}

resource "openstack_networking_port_v2" "builder" {
    
    name = var.name
    network_id = data.openstack_networking_subnet_v2.builder.network_id
    fixed_ip {
        subnet_id = data.openstack_networking_subnet_v2.builder.id
    }
    security_group_ids = [
        data.openstack_networking_secgroup_v2.default.id
    ]
    admin_state_up = "true"
    binding {
        vnic_type = "direct"
        profile = jsonencode(
            {
              #  capabilities = ["switchdev"]
            }
        )
    }
}

resource "local_file" "pkrvars" {
    content  = "port_id = \"${openstack_networking_port_v2.builder.id}\"\n"
    filename = "${path.module}/builder.pkrvars.hcl"
}

output "port_id" {
    value = openstack_networking_port_v2.builder.id
}
