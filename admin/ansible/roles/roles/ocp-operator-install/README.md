# `ocp-operator-install`

Use this role to install an operator.
This role creates a namespace for the operator (if a namespace does not already exist), it creates an operator group for the operator, and it creates a subscription for the operator.
Because this role is generic, it does not perform additional configuration required by many operators.

This role creates the following resources:

- Project
- Namespace
- OperatorGroup
- Subscription

Then the following resources are created automatically by the cluster:

- ClusterServiceVersion
- InstallPlan

## Requirements

This role uses the redhat.openshift and kubernetes.core Ansible collections.
Your DLE must pre-install these Ansible collections on workstation.

## Role Variables

- See `group_vars/all` for example variables

## Dependencies

This role requires that you access the OpenShift cluster as a user with the cluster-admin role. The lab user on the utility machine can run commands as the system:admin user using the kubeconfig file located at /home/lab/ocp4/auth/kubeconfig.

## Example Playbook

See the following playbooks for example:

- `ansible/openshift-virtualization/install-*.yaml`

## License

BSD-3-Clause

## Author Information

- https://www.redhat.com/en/services/training-and-certification
- https://spaces.redhat.com/display/PTL
- https://spaces.redhat.com/display/PTL/DynoLabs
- https://jenkins.prod.nextcle.com/userContent/dynolabs-docs/latest/index.html
- https://github.com/RedHatTraining/
