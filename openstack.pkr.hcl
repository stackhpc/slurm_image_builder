# Use like:
#  $ PACKER_LOG=1 packer build --on-error=ask -var-file=<something>.pkrvars.hcl openstack.pkr.hcl

# "timestamp" template function replacement:s
locals {timestamp = formatdate("YYMMDD-hhmm", timestamp())}

variable "source_image_name" {
  type = string
  default = "Rocky-8-GenericCloud-8.6.20220702.0.x86_64.qcow2"
}

variable "ssh_bastion_host" {
  type = string
  default = "128.232.222.183"
}

variable "ssh_bastion_username" {
  type = string
  default = "slurm-app-ci"
}

source "openstack" "openhpc" {
  flavor = "vm.ska.cpu.general.tiny"
  networks = ["4b6b2722-ee5b-40ec-8e52-a6610e14cc51"] # portal-internal
  source_image_name = "${var.source_image_name}" # NB: must already exist in OpenStack
  ssh_username = "rocky"
  ssh_timeout = "20m"
  ssh_private_key_file = "~/.ssh/id_rsa"
  ssh_keypair_name = "slurm-app-ci"
  ssh_bastion_host = "${var.ssh_bastion_host}"
  ssh_bastion_username = "${var.ssh_bastion_username}"
  ssh_bastion_private_key_file = "~/.ssh/id_rsa"
  image_name = "${source.name}-${local.timestamp}.qcow2"
  ssh_clear_authorized_keys = true
}

build {
  source "source.openstack.openhpc" {
  }

  provisioner "ansible" {
    playbook_file = "playbooks/build.yml" # can't use ansible FQCN here
    use_proxy = false # see https://www.packer.io/docs/provisioners/ansible#troubleshooting
    extra_arguments = ["-v"]
    ansible_ssh_extra_args = ["-o ProxyCommand='ssh ${var.ssh_bastion_username }@${ var.ssh_bastion_host} -W %h:%p'"]
    # keep_inventory_file = true
  }

  post-processor "manifest" {
    custom_data  = {
      source = "${source.name}"
    }
  }
}
