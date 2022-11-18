# "timestamp" template function replacement:s
locals {timestamp = formatdate("YYMMDD-hhmm", timestamp())}

variable "source_image_name" {
  type = string
  default = "Rocky-8-GenericCloud-8.6.20220702.0.x86_64.qcow2"
}

variable "flavor_name" {
  type = string
}

variable "network_ids" {
  type = list(string)
}

source "openstack" "rocky" {
  flavor = var.flavor_name
  source_image_name = var.source_image_name
  ssh_username = "rocky"
  ssh_timeout = "20m"
  image_name = "${source.name}-${local.timestamp}.qcow2"
  networks = var.network_ids
}

build {
  source "source.openstack.rocky" {
  }

  provisioner "ansible" {
    playbook_file = "build.yml"
    use_proxy = false # see https://www.packer.io/docs/provisioners/ansible#troubleshooting
    extra_arguments = ["-v"]
  }

  post-processor "manifest" {
    custom_data  = {
      source = source.name
    }
  }
}
