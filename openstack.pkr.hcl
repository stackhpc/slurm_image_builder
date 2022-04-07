# Use like:
#  $ PACKER_LOG=1 packer build --on-error=ask -var-file=<something>.pkrvars.hcl openstack.pkr.hcl

# "timestamp" template function replacement:s
locals { timestamp = formatdate("YYMMDD-hhmm", timestamp())}

variable "networks" {
  type = list(string)
}

variable "source_image_name" {
  type = string
}

variable "flavor" {
  type = string
}

variable "ssh_username" {
  type = string
  default = "rocky"
}

variable "ssh_private_key_file" {
  type = string
  default = "~/.ssh/id_rsa"
}

variable "ssh_keypair_name" {
  type = string
}

variable "security_groups" {
  type = list(string)
}

variable "image_visibility" {
  type = string
  default = "private"
}

variable "ssh_bastion_host" {
  type = string
}

variable "ssh_bastion_username" {
  type = string
}

variable "ssh_bastion_private_key_file" {
  type = string
  default = "~/.ssh/id_rsa"
}

source "openstack" "openhpc" {
  flavor = "${var.flavor}"
  networks = "${var.networks}"
  source_image_name = "${var.source_image_name}" # NB: must already exist in OpenStack
  ssh_username = "${var.ssh_username}"
  ssh_timeout = "20m"
  ssh_private_key_file = "${var.ssh_private_key_file}" # TODO: doc same requirements as for qemu build?
  ssh_keypair_name = "${var.ssh_keypair_name}" # TODO: doc this
  ssh_bastion_host = "${var.ssh_bastion_host}"
  ssh_bastion_username = "${var.ssh_bastion_username}"
  ssh_bastion_private_key_file = "${var.ssh_bastion_private_key_file}"
  security_groups = "${var.security_groups}"
  image_name = "ohpc-${source.name}-${local.timestamp}.qcow2"
  image_visibility = "${var.image_visibility}"
}

build {
  source "source.openstack.openhpc" {
  }

  provisioner "ansible" {
    playbook_file = "playbooks/build.yml" # can't use ansible FQCN here
    use_proxy = false # see https://www.packer.io/docs/provisioners/ansible#troubleshooting
    extra_arguments = ["-v"]
  }

  post-processor "manifest" {
    custom_data  = {
      source = "${source.name}"
    }
  }
}
