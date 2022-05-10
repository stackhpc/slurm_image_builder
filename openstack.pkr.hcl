# Use like:
#  $ PACKER_LOG=1 packer build --on-error=ask -var-file=<something>.pkrvars.hcl openstack.pkr.hcl

# "timestamp" template function replacement:s
locals { timestamp = formatdate("YYMMDD-hhmm", timestamp())}

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
  type = string
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
  ports = [var.port_id]
}

build {
  source "source.openstack.openhpc" {
    name = "inbox"
    image_name = "openhpc-${local.timestamp}.qcow2"
  }
  
  source "source.openstack.openhpc" {
    name = "ofed"
    image_name = "openhpc-${local.timestamp}-ofed.qcow2"
  }

  provisioner "ansible" {
    playbook_file = "playbooks/build.yml" # can't use ansible FQCN here
    use_proxy = false # see https://www.packer.io/docs/provisioners/ansible#troubleshooting
    override = {
      inbox = {
        extra_arguments = ["-v"]
      }
      ofed = {
        extra_arguments = concat(["-v"], ["-e", "ofed_install=yes"])
      }
    }
    ansible_ssh_extra_args = ["-o ProxyCommand='ssh ${var.ssh_bastion_username }@${ var.ssh_bastion_host} -W %h:%p'"]
  }

  post-processor "manifest" {
    custom_data  = {
      source = "${source.name}"
    }
  }
}
