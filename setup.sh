#!/bin/bash
# Setup script for OpenShift admin tools
# Checks dependencies and installs required Python packages

set -euo pipefail

# Configuration
REQUIRED_YQ_VERSION="4.0.0"
CHECK_ONLY=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        *)
            echo "Usage: $0 [--check-only]" >&2
            echo ""
            echo "Options:"
            echo "  --check-only    Check dependencies without installing Python packages"
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "OpenShift Admin Tools - Setup"
echo "=========================================="
echo ""

# Detect platform
if [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macOS"
elif [[ -f /etc/redhat-release ]]; then
    PLATFORM="RHEL"
else
    echo "⚠ Warning: Unsupported platform detected"
    echo "This script supports macOS and RHEL only"
    echo ""
    PLATFORM="unknown"
fi

echo "Platform: $PLATFORM"
echo ""
echo "Checking dependencies..."
echo ""

# Track missing dependencies
MISSING_DEPS=()
WARNINGS=()

# Check Python 3
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "✓ Python $PYTHON_VERSION"
else
    echo "✗ Python 3 not found"
    MISSING_DEPS+=("python3")
fi

# Check pip3
if command -v pip3 &> /dev/null; then
    echo "✓ pip3"
else
    echo "✗ pip3 not found"
    MISSING_DEPS+=("pip3")
fi

# Check yq
if command -v yq &> /dev/null; then
    YQ_VERSION=$(yq --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

    # Compare versions (convert to comparable numbers)
    YQ_MAJOR=$(echo "$YQ_VERSION" | cut -d. -f1)
    REQUIRED_MAJOR=$(echo "$REQUIRED_YQ_VERSION" | cut -d. -f1)

    if [[ "$YQ_MAJOR" -ge "$REQUIRED_MAJOR" ]]; then
        echo "✓ yq v$YQ_VERSION"
    else
        echo "✗ yq v$YQ_VERSION (v4+ required)"
        WARNINGS+=("yq_version")
        echo "  Warning: Export scripts require yq v4.45.4 or later"
        echo "  Your version: v$YQ_VERSION"
    fi
else
    echo "✗ yq not found"
    MISSING_DEPS+=("yq")
fi

# Check oc (OpenShift CLI)
if command -v oc &> /dev/null; then
    OC_VERSION=$(oc version --client 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown")
    echo "✓ oc (OpenShift CLI) $OC_VERSION"
else
    echo "✗ oc (OpenShift CLI) not found"
    MISSING_DEPS+=("oc")
fi

# Check Python dependencies
echo ""
echo "Python dependencies:"

if command -v python3 &> /dev/null; then
    if python3 -c "import ruamel.yaml" 2>/dev/null; then
        RUAMEL_VERSION=$(python3 -c "import ruamel.yaml; print(ruamel.yaml.version_info)" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "installed")
        echo "✓ ruamel.yaml $RUAMEL_VERSION"
    else
        echo "✗ ruamel.yaml not installed"
        MISSING_DEPS+=("ruamel.yaml")
    fi
fi

# Show missing dependencies
echo ""
if [[ ${#MISSING_DEPS[@]} -eq 0 && ${#WARNINGS[@]} -eq 0 ]]; then
    echo "=========================================="
    echo "✓ All dependencies satisfied!"
    echo "=========================================="
    echo ""
    echo "You can now use the admin tools:"
    echo "  ./admin/yaml_decoupler.py --help"
    echo "  ./admin/export-*.sh <resource_name>"
    exit 0
fi

# Display installation instructions
if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo "=========================================="
    echo "⚠ Missing Dependencies"
    echo "=========================================="
    echo ""

    for dep in "${MISSING_DEPS[@]}"; do
        case $dep in
            python3|pip3)
                echo "Python 3 and pip3:"
                if [[ "$PLATFORM" == "macOS" ]]; then
                    echo "  brew install python3"
                elif [[ "$PLATFORM" == "RHEL" ]]; then
                    echo "  sudo dnf install python3 python3-pip"
                fi
                echo ""
                ;;
            yq)
                echo "yq (YAML processor) v4+:"
                if [[ "$PLATFORM" == "macOS" ]]; then
                    echo "  brew install yq"
                elif [[ "$PLATFORM" == "RHEL" ]]; then
                    echo "  # Download latest release:"
                    echo "  sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq"
                    echo "  sudo chmod +x /usr/local/bin/yq"
                fi
                echo ""
                ;;
            oc)
                echo "oc (OpenShift CLI):"
                if [[ "$PLATFORM" == "macOS" ]]; then
                    echo "  brew install openshift-cli"
                elif [[ "$PLATFORM" == "RHEL" ]]; then
                    echo "  # Method 1: From RHEL repos (if available)"
                    echo "  sudo dnf install origin-clients"
                    echo ""
                    echo "  # Method 2: Download from Red Hat"
                    echo "  # Visit: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/stable/"
                fi
                echo ""
                ;;
            ruamel.yaml)
                # This will be auto-installed below if not in --check-only mode
                ;;
        esac
    done
fi

# Show warnings
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    echo "=========================================="
    echo "⚠ Warnings"
    echo "=========================================="
    echo ""

    for warning in "${WARNINGS[@]}"; do
        case $warning in
            yq_version)
                echo "yq version is too old (v3 detected, v4+ required):"
                if [[ "$PLATFORM" == "macOS" ]]; then
                    echo "  brew upgrade yq"
                elif [[ "$PLATFORM" == "RHEL" ]]; then
                    echo "  # Remove old version and install v4+:"
                    echo "  sudo rm -f /usr/local/bin/yq"
                    echo "  sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq"
                    echo "  sudo chmod +x /usr/local/bin/yq"
                fi
                echo ""
                ;;
        esac
    done
fi

# Exit if in check-only mode
if [[ "$CHECK_ONLY" == true ]]; then
    echo "=========================================="
    echo "Check complete (--check-only mode)"
    echo "=========================================="
    exit 1
fi

# Auto-install Python dependencies if Python is available
if command -v python3 &> /dev/null && command -v pip3 &> /dev/null; then
    # Check if ruamel.yaml is missing
    if ! python3 -c "import ruamel.yaml" 2>/dev/null; then
        echo "=========================================="
        echo "Installing Python Dependencies"
        echo "=========================================="
        echo ""

        # Determine pip flags
        PIP_FLAGS="--user"
        if [[ "$PLATFORM" == "macOS" ]]; then
            PIP_FLAGS="--user --break-system-packages"
            echo "Using --break-system-packages for macOS"
        fi

        if pip3 install $PIP_FLAGS -r admin/requirements.txt; then
            echo ""
            echo "✓ Python dependencies installed successfully"
        else
            echo ""
            echo "✗ Failed to install Python dependencies"
            echo ""
            echo "Try manual installation:"
            echo "  pip3 install --user ruamel.yaml"
            echo ""
            echo "Or use a virtual environment:"
            echo "  python3 -m venv venv"
            echo "  source venv/bin/activate"
            echo "  pip install -r admin/requirements.txt"
            exit 1
        fi
    fi
fi

# Final status
echo ""
echo "=========================================="
if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    echo "⚠ Setup incomplete"
    echo "=========================================="
    echo ""
    echo "After installing missing dependencies, run:"
    echo "  ./setup.sh"
    exit 1
else
    echo "✓ Setup complete!"
    echo "=========================================="
    echo ""
    echo "You can now use the admin tools:"
    echo "  ./admin/yaml_decoupler.py --help"
    echo "  ./admin/export-*.sh <resource_name>"
    exit 0
fi
