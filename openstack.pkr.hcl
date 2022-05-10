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
  default = "Rocky-8-GenericCloud-8.5-20211114.2.x86_64"
}

variable "ssh_bastion_host" {
  type = string
  default = "128.232.222.183"
}

variable "ssh_bastion_username" {
  type = string
  default = "slurm-app-ci"
}

variable "port_id" {
  type = string # set by Terraform templating arcus.builder.pkrvars.hcl
}

variable "ofed_install" {
  type = string # set by github CI via environment variables
  default = "false"
}

source "openstack" "openhpc" {
  flavor = "vm.alaska.cpu.general.small"
  source_image_name = "${var.source_image_name}" # NB: must already exist in OpenStack
  ssh_username = "rocky"
  ssh_timeout = "20m"
  ssh_private_key_file = "~/.ssh/id_rsa"
  ssh_keypair_name = "slurm-app-ci"
  ssh_bastion_host = "128.232.222.183"
  ssh_bastion_username = "${var.ssh_bastion_username}"
  ssh_bastion_private_key_file = "~/.ssh/id_rsa"
  image_name = "${source.name}-${local.timestamp}${local.image_name_suffix[var.ofed_install]}.qcow2"
  ports = [var.port_id]
}

build {
  source "source.openstack.openhpc" {
  }

  provisioner "ansible" {
    playbook_file = "playbooks/build.yml" # can't use ansible FQCN here
    use_proxy = false # see https://www.packer.io/docs/provisioners/ansible#troubleshooting
    extra_arguments = ["-v", "-e", "ofed_install=${var.ofed_install}"]
    ansible_ssh_extra_args = ["-o ProxyCommand='ssh ${var.ssh_bastion_username }@${ var.ssh_bastion_host} -W %h:%p'"]
  }

  post-processor "manifest" {
    custom_data  = {
      source = "${source.name}"
    }
  }
}
