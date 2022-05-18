# Use like:
#  $ PACKER_LOG=1 packer build --on-error=ask -var-file=<something>.pkrvars.hcl openstack.pkr.hcl

# "timestamp" template function replacement:s
locals {
  timestamp = formatdate("YYMMDD-hhmm", timestamp())
  # a lookup table to change image name with var.ofed_install:
  image_name_suffix = {
    true = "-ofed"
    false = ""
  }
}

variable "source_image_name" {
  type = string
  default = "Rocky-8-GenericCloud-8.5-20211114.2.x86_64.qcow2" # NB: 8.6 doesn't seem to include sudo!
}

variable "port_id" {
  type = string # set by Terraform templating arcus.builder.pkrvars.hcl
}

variable "ofed_install" {
  type = string # set by CI via environment variables
  default = "false"
}

source "openstack" "rocky" {
  flavor = "m3.medium"
  source_image_name = "${var.source_image_name}" # NB: must already exist in OpenStack
  ssh_username = "rocky"
  ssh_timeout = "20m"
  ssh_private_key_file = "~/.ssh/id_rsa"
  ssh_keypair_name = "rocky_bastion_v2"
  image_name = "Rocky-8.6-${local.timestamp}${local.image_name_suffix[var.ofed_install]}.qcow2"
  ports = [var.port_id]
}

build {
  source "source.openstack.rocky" {
  }

  provisioner "ansible" {
    playbook_file = "build.yml"
    use_proxy = false # see https://www.packer.io/docs/provisioners/ansible#troubleshooting
    extra_arguments = ["-v", "-e", "ofed_install=${var.ofed_install}"]
  }

  post-processor "manifest" {
    custom_data  = {
      source = "${source.name}"
    }
  }
}
