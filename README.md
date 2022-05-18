An OpenStack image builder for Rocky Linux optionally including NVIDIA/Mellanox OFED.

This will create an image which is based on a Rocky Linux x86 generic cloud image, plus all dnf upgrades, optionally plus OFED.

It uses Packer with the OpenStack builder and Ansible provisioner.

To provide a functioning environment for the optional OFED install this creates a direct-mode port and attaches the Packer build VM to it. If the Packer variable `ofed_install` is set to `'true'` (NB: a string) then the VM configuration used must expose a Mellanox channel adaptor

The created images contain the git description of this repo state used at build time in `/var/lib/misc/build.txt`.

# Creating Images

TODO: Describe how to run in CI.

Current manual steps, assuming a Rocky Linux 8.5 host on NeSI:

1. Clone the repo
1. Install environment: `./setup.sh`
1. Activate venv if necessary: `. venv/bin/activate`
1. Install Terraform
1. Create the port:

    terraform init
    terraform apply

1. Set OpenStack credentials, e.g.: `export OS_CLOUD=openstack`
1. Build image: `PACKER_LOG=1 /usr/bin/packer build --on-error=ask -var-file=builder.pkrvars.hcl openstack.pkr.hcl`

**NB:** The full path to the Hashicorp Packer binary should be used to avoid getting `/usr/sbin/packer` (`cracklib-packer`) instead.

# Usage of Images

- Upload an image built by this repo to your OpenStack.
- Configure the provisioner to use an image built by this repo for all nodes (control, compute and login) - [smslabs example](https://github.com/stackhpc/ansible-slurm-appliance/commit/cc362e573f07829bcd6eb6475667cbf4ba26b58d).
- Ensure the appliance repo includes [PR#166](https://github.com/stackhpc/ansible-slurm-appliance/pull/166). This modifies the dependencies in `requirements.yml`.
- If the `ansible-galaxy {role,collection} install ...` [installation commands](https://github.com/stackhpc/ansible-slurm-appliance/#installation-on-deployment-host) have already been run, rerun them to update dependencies.
- Set `prometheus_skip_install: true` in your environment, e.g. see here. This avoids prometheus binaries being downloaded to localhost and then propagated to the relevant node(s).
- Continue Slurm appliance setup/deploy/configuration as normal.
