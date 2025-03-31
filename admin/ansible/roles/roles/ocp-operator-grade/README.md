# `ocp-operator-grade`

This role verifies the resources that are used to install an operator in the OpenShift cluster.

- Project
- Namespace
- OperatorGroup
- Subscription
- CustomResourceDefinition

This role does not check resources that are created automatically by the cluster:

- ClusterServiceVersion
- InstallPlan

Also, this role does not check extra resources that are created or required by the operator.

## Requirements

This role uses the redhat.openshift and kubernetes.core Ansible collections.
Your DLE must pre-install these Ansible collections on workstation.

## Role Variables

- See `group_vars/all` for example variables

## Dependencies

This role requires that you access the OpenShift cluster as a user with the cluster-admin role. The lab user on the utility machine can run commands as the system:admin user using the kubeconfig file located at /home/lab/ocp4/auth/kubeconfig.

## Example Playbook

See the following playbooks for example:

- `ansible/openshift-virtualization/grade-*.yaml`

## License

BSD-3-Clause

## Author Information

- https://www.redhat.com/en/services/training-and-certification
- https://spaces.redhat.com/display/PTL
- https://spaces.redhat.com/display/PTL/DynoLabs
- https://jenkins.prod.nextcle.com/userContent/dynolabs-docs/latest/index.html
- https://github.com/RedHatTraining/
