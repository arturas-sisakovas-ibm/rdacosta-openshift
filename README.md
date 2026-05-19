# OpenShift Virtualization Training Materials

Training materials and administrative tools for Red Hat OpenShift courses.

## Overview

This repository contains:
- **YAML manifests** for OpenShift resources 
- **Export scripts** for extracting clean, reproducible Kubernetes/OpenShift resource definitions
- **Python utilities** for YAML manipulation and resource management
- **Ansible playbooks** for automation and lab environment setup

## Quick Start

### 1. Clone the Repository

```bash
git clone https://gitlab.com/rgdacosta/openshift.git
cd openshift
```

### 2. Install Dependencies

Run the setup script to check dependencies and install Python libraries:

```bash
./setup.sh
```

The script will:
- Check for required tools (Python 3, pip3, yq v4+, oc)
- Auto-install Python dependencies (ruamel.yaml)
- Show platform-specific installation instructions for missing tools

**Check dependencies without installing:**
```bash
./setup.sh --check-only
```

**Manual Python installation:**
```bash
pip3 install -r admin/requirements.txt
```

### 3. Verify Installation

```bash
./admin/yaml_decoupler.py --help
```

## Admin Tools (`admin/` directory)

### Export Scripts (v3.0)

Shell scripts for extracting clean YAML manifests from OpenShift resources. These scripts:
- Remove runtime metadata (managedFields, ownerReferences, resourceVersion, etc.)
- Preserve user-defined annotations and labels
- Delete system-generated annotations/labels
- Produce portable, reproducible YAML suitable for training environments

**Available scripts:**
```bash
export-cm.sh <configmap_name>         # ConfigMaps
export-deploy.sh <deployment_name>    # Deployments
export-is.sh <imagestream_name>       # ImageStreams
export-netpol.sh <networkpolicy_name> # NetworkPolicies
export-project.sh <project_name>      # Projects
export-pvc.sh <pvc_name>              # PersistentVolumeClaims
export-restore.sh <restore_name>      # Velero Restores
export-route.sh <route_name>          # Routes
export-secret.sh <secret_name>        # Secrets (with security warning)
export-svc.sh <service_name>          # Services
export-vm.sh <vm_name>                # VirtualMachines
```

**Example usage:**
```bash
# Export a ConfigMap to a clean YAML file
./admin/export-cm.sh my-config > configmap_my-config.yaml

# Export a VirtualMachine (removes runtime fields, sanitises MAC addresses)
./admin/export-vm.sh rhel9-vm > vm_rhel9.yaml

# Export a Secret (includes base64-encoded data with security warning)
./admin/export-secret.sh db-password > secret_db-password.yaml
```

**Requirements:**
- OpenShift CLI (`oc`) 4.x
- yq v4.45.4+ (YAML processor) - Install with: `brew install yq` (macOS) or `wget` from GitHub releases

**Documentation:**
- [CHANGES.md](admin/CHANGES.md) - Version 2.0 changelog (yq v4 migration)
- [CHANGES-v3.md](admin/CHANGES-v3.md) - Version 3.0 changelog (selective filtering)

### YAML Decoupler

Python script for splitting multi-document YAML files into individual resource files.

**Features:**
- Preserves YAML formatting and structure (uses ruamel.yaml)
- Configurable filename patterns: `{kind}_{name}.yaml` or `{kind}_{namespace}_{name}.yaml`
- Selective extraction by resource kind
- Dry-run mode for previewing
- Output directory support

**Usage:**
```bash
# Basic usage - extract all resources to current directory
./admin/yaml_decoupler.py stack.yaml

# Extract to specific directory with namespace in filenames
./admin/yaml_decoupler.py stack.yaml -o extracted/ -n

# Preview extraction without writing files
./admin/yaml_decoupler.py stack.yaml --dry-run --verbose

# Extract only specific resource types
./admin/yaml_decoupler.py stack.yaml -k Service -k ConfigMap -o configs/

# Show help and all options
./admin/yaml_decoupler.py --help
```

**Options:**
```
-o, --output-dir DIR    Output directory (default: current)
-n, --include-namespace Include namespace in filename
-k, --kind KIND         Extract only specified kinds (repeatable)
--dry-run               Preview without writing
-v, --verbose           Show detailed processing
-f, --force             Overwrite existing files
--summary               Show extraction statistics
```

## OpenShift Virtualization Manifests

### Templates

- `template_vmcf_vmcp-rhel10-httpd.yaml` - VM template with common templates (flavor/cloud-init)
- `template_no_vmcf_vmcp-rhel10-httpd.yaml` - VM template without common templates
- `template_rhel9-custom.yaml` - RHEL 9 custom template

### Instance Types & Preferences

- `vmcp_rhel10.1.yaml` - RHEL 10 preference (no requirements - avoids conflicts)
- Various instance type definitions

### Virtual Machines

- `golden-vm.yaml` - Golden image VM
- `vm_generic.yaml` - Generic VM example
- Stack examples: `stack_golden-vm.yaml`, `stack_vm1.yaml`, `stack_vm2.yaml`, `stack_webservers.yaml`

**Note:** All manifests with `yum_repos` sections include GPG warning comments for lab environment usage.

## Requirements

### System Tools

All checked automatically by `./setup.sh`:

- **Python**: 3.8+ (3.14+ recommended)
- **pip3**: Python package manager
- **yq**: v4.0+ (YAML processor, NOT v3)
  - macOS: `brew install yq`
  - RHEL: Download from https://github.com/mikefarah/yq/releases
- **oc**: OpenShift CLI v4.12+
  - macOS: `brew install openshift-cli`
  - RHEL: `sudo dnf install origin-clients`
- **Bash**: 4.0+ (for export scripts)

### Python Dependencies
Installed automatically by `./setup.sh`:
- `ruamel.yaml>=0.18.0` - YAML round-trip preservation

### Optional
- **Ansible**: 2.9+ (for playbooks)
- **Git**: Version control

## Project Structure

```
openshift/
├── admin/                          # Administrative tools
│   ├── export-*.sh                # Resource export scripts (11 scripts)
│   ├── yaml_decoupler.py          # YAML splitting utility
│   ├── requirements.txt           # Python dependencies
│   ├── CHANGES.md                 # Export scripts v2.0 changelog
│   └── CHANGES-v3.md              # Export scripts v3.0 changelog
├── setup.sh                       # One-time setup script
├── README.md                      # This file
├── .gitignore                     # Git ignore patterns
├── template_*.yaml                # VM templates
├── vm*.yaml                       # VirtualMachine definitions
├── stack_*.yaml                   # Multi-resource stacks
└── [other OpenShift resources]
```

## Training Environment Notes

### Security Warnings

1. **Secrets Export**: `export-secret.sh` exports base64-encoded secret data for training purposes. **DO NOT** commit these to Git or use in production environments.

2. **GPG Checking Disabled**: Several manifests disable GPG checking for lab environment convenience. This is **ONLY** appropriate for isolated training environments.

3. **Generated MAC Addresses**: `export-vm.sh` sanitises MAC addresses to `52:54:00:00:00:00` for portability.

### Export Scripts Design Decisions

**Preserved Fields:**
- `metadata.namespace` - Shows resource origin
- `metadata.name` - Resource identifier
- User-defined annotations and labels

**Deleted Fields:**
- All runtime metadata (managedFields, resourceVersion, uid, creationTimestamp, etc.)
- System annotations (kubectl.kubernetes.io/*, openshift.io/*, pv.kubernetes.io/*, etc.)
- System labels (kubernetes.io/metadata.name, pod-security.kubernetes.io/*)
- Resource-specific runtime fields (spec.clusterIP, spec.host, status, etc.)

See [CHANGES-v3.md](admin/CHANGES-v3.md) for complete field deletion matrix.

## Version History

| Version | Date | Key Changes |
|---------|------|-------------|
| 1.0 | 2026-05-18 | Initial yq v3 scripts |
| 2.0 | 2026-05-18 | yq v4 migration, error handling, namespace preservation |
| 3.0 | 2026-05-18 | Selective annotation/label filtering, consistent runtime field deletion |

## Author

Ricardo da Costa  
Senior Red Hat Instructor (materials maintained in personal capacity)

## Licence

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

Copyright (c) 2026 Ricardo da Costa

## Disclaimer

This repository is maintained in a personal capacity. It is not an official Red Hat product and is not supported by Red Hat. The materials are provided for educational and training purposes.
