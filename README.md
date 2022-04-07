# Ansible Collection - stackhpc.slurm_image_builder

An image builder for the StackHPC [Slurm appliance](https://github.com/stackhpc/ansible-slurm-appliance/).

The Slurm appliance normally uses a Rocky Linux Generic Cloud image 8.5. It can build its own images from this.

However downloading all the packages and other binaries required can be quite slow, especially on a slow network. The tools here create an OpenStack image which contain the packages and binaries for all cluster nodes, which can be used as an alternative starting point for the Slurm appliance. They contain no configuration and the normal Slurm appliance playbooks must still be run once instance have been deployed with these images.

# Creating Images

TODO: Run in CI.

Current manual steps, assuming a Rocky Linux 8.5 host on [sms-lab](https://api.sms-lab.cloud/):

1. Clone the repo
1. Install environment: `./setup.sh`
1. Activate venv if necessary: `. venv/bin/activate`
1. Build image: `PACKER_LOG=1 packer build --on-error=ask -var-file=smslabs.builder.pkrvars.hcl openstack.pkr.hcl`

# Usage of Images

- Upload an image built by this repo to your OpenStack.
- Configure the provisioner to use an image built by this repo for all nodes (control, compute and login) - [smslabs example](https://github.com/stackhpc/ansible-slurm-appliance/commit/cc362e573f07829bcd6eb6475667cbf4ba26b58d).
- Ensure the appliance repo includes [PR#166](https://github.com/stackhpc/ansible-slurm-appliance/pull/166). This modifies the dependencies in `requirements.yml`.
- If the `ansible-galaxy {role,collection} install ...` [installation commands](https://github.com/stackhpc/ansible-slurm-appliance/#installation-on-deployment-host) have already been run, rerun them to update dependencies.
- Set `prometheus_skip_install: true` in your environment, e.g. see here. This avoids prometheus binaries being downloaded to localhost and then propagated to the relevant node(s).
- Continue Slurm appliance setup/deploy/configuration as normal.

# What this does
This uses Ansible from Packer to:
- Create a VM using a Rocky Linux 8.5 generic cloud image.
- Update all packages and reboot if necessary.
- Install appropriate packages, at latest version where possible.
- Install binaries for Grafana, Prometheus and node-exporter.

Sections below give details and non-obvious features.

## DNF packages

The role adds rpm keys and adds/enables various repos as used by the appliance and dependencies. It then uses `ansible.builtin.dnf` commands to install packages.

Unfortunately the obvious approach of using an (unversioned) list of packages from an existing cluster runs into dependency solve problems with dependencies for Open Ondemand. See `roles/builder/tasks/dnf_packages.yml` for the approach which worked. Note package lists are manually collated from the appliance and dependencies. The update step is done first to try to ensure that any kernel-dependent packages get the correct version.

## Monitoring binaries
In the Slurm appliance the monitoring stack is installed using `cloudalchemy` roles. The appropriate playbooks in `roles/builder/tasks/` use plays extracted/modified from these roles to install the necessary binaries.

### [cloudalchemy.grafana](https://github.com/cloudalchemy/ansible-grafana)

This role behaves ok and simply no-ops the install if binaries already exist in the image. Note that without the grafana repo file (templated by this tooling), an old version of grafana is installed (from some other repo) which does not appear to read all the config, so the appliance does not set the admin username/password correctly.


### [cloudalchemy.node_exporter](https://github.com/cloudalchemy/ansible-node-exporter)

In the upstream version of this role:
- `preflight.yml` detects whether binaries already exist.
- If they don't, the `install.yml` playbook downloads binaries to localhost and then propagates them to hosts. There is no way to avoid this approach.
- If they do, `install.yml` is skipped.

However the `install.yml` playbook also creates the group/user, which means startup fails if the binaries exist but the users have not been ceated.

A fork of the role `feature/no-install` ([here](https://github.com/stackhpc/ansible-node-exporter/tree/feature/no-install)) has therefore been created. This moves user creation into `configure.yml`, along with systemd unit file creation which actually requires the user/group.

### [cloudalchemy.prometheus](https://github.com/cloudalchemy/ansible-prometheus)

This role also uses the "download to localhost and propagate" approach. It does not check for pre-existing binaries, but provides a role variable `prometheus_skip_install: true` which means it will not try to manage the binaries. This variable should therefore be set when using images built using this tooling, as shown above.
