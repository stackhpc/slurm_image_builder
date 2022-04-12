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
  default = "Private"
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

locals {
  proxy_command = "'ssh ${var.ssh_bastion_username }@${ var.ssh_bastion_host} -W %h:%p'"
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
  image_name = "${source.name}-${local.timestamp}.qcow2"
}

build {
  source "source.openstack.openhpc" {
  }

  provisioner "ansible" {
    playbook_file = "playbooks/build.yml" # can't use ansible FQCN here
    use_proxy = false # see https://www.packer.io/docs/provisioners/ansible#troubleshooting
    extra_arguments = ["-v"]
    # ansible equivalent:
    #   ansible_ssh_common_args: '-o ProxyCommand="ssh {{ bastion_user }}@{{ bastion_ip }} -W %h:%p"'
    # ansible_ssh_extra_args = ["-o ProxyCommand='ssh ${var.ssh_bastion_username }@${ var.ssh_bastion_host} -W %h:%p'"]
    # gets mangled on github as:
    # --ssh-extra-args '-oProxyCommand='ssh slurm-app-ci@185.45.78.150'-W%h:%p'
    ansible_env_vars = ["ANSIBLE_SSH_ARGS='-o ProxyCommand=${local.proxy_command}'"]
  }

  post-processor "manifest" {
    custom_data  = {
      source = "${source.name}"
    }
  }
}
