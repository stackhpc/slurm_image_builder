An OpenStack image builder for Rocky Linux with NVIDIA/Mellanox OFED.

This will create an image which is based on a Rocky Linux 8.6 x86 generic cloud image, plus all dnf upgrades, plus OFED.

It uses Packer with the OpenStack builder and Ansible provisioner.

The created images contain the git description of this repo state used at build time in `/var/lib/misc/build.txt`.

# Creating Images

Manual steps, assuming a Rocky Linux 8.x host:

1. Ensure a [Rocky-8-GenericCloud-8.6.20220702.0.x86_64.qcow2](https://download.rockylinux.org/pub/rocky/8/images/Rocky-8-GenericCloud-8.6.20220702.0.x86_64.qcow2) image is available in OpenStack
1. Clone this repo
1. Install environment: `./setup.sh`
1. Activate venv if necessary: `. venv/bin/activate`
1. Create a `cloudname.pkrvars.hcl` file detailing the flavor and network ID to use, see e.g. `arcus.pkrvars.hcl`
1. Expose OpenStack credentials, e.g.: `export OS_CLOUD=openstack`
1. Build image e.g: `PACKER_LOG=1 /usr/bin/packer build --on-error=ask -var-file=cloudname.pkrvars.hcl openstack.pkr.hcl`

**NB:** The full path to the Hashicorp Packer binary should be used to avoid getting `/usr/sbin/packer` (`cracklib-packer`) instead.
