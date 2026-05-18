#!/usr/bin/env python3

"""
YAML Decoupler - Extract individual Kubernetes/OpenShift resources from multi-document YAML files

Splits a YAML manifest containing multiple resources into separate files with the naming
convention: {kind}_{name}.yaml (or {kind}_{namespace}_{name}.yaml with --include-namespace)

Preserves YAML formatting and structure from the original file.
"""

import argparse
import os
import re
import sys
from pathlib import Path
from typing import Dict, Optional, Set

try:
    from ruamel.yaml import YAML
    from ruamel.yaml.error import YAMLError
except ImportError:
    print("Error: ruamel.yaml is required. Install with: pip3 install ruamel.yaml", file=sys.stderr)
    sys.exit(1)


class YAMLDecoupler:
    """Handles extraction of individual resources from multi-document YAML files"""

    def __init__(self, output_dir: str = ".", include_namespace: bool = False,
                 dry_run: bool = False, verbose: bool = False, force: bool = False,
                 kinds: Optional[Set[str]] = None):
        self.output_dir = Path(output_dir)
        self.include_namespace = include_namespace
        self.dry_run = dry_run
        self.verbose = verbose
        self.force = force
        self.kinds = {k.lower() for k in kinds} if kinds else None

        # Configure YAML processor for round-trip preservation
        self.yaml = YAML()
        self.yaml.explicit_start = True  # Add --- separator
        self.yaml.preserve_quotes = True
        self.yaml.default_flow_style = False
        self.yaml.width = 4096  # Prevent line wrapping

        # Statistics
        self.stats = {
            'processed': 0,
            'skipped': 0,
            'errors': 0,
            'written': 0
        }

    def sanitize_filename(self, text: str) -> str:
        """
        Sanitize text for safe filename usage.

        Kubernetes resource names can contain characters unsafe for filesystems.
        Replace problematic characters with underscores.
        """
        # Allow alphanumeric, dash, dot, underscore
        return re.sub(r'[^\w\-.]', '_', text)

    def generate_filename(self, doc: Dict) -> Optional[str]:
        """
        Generate output filename from resource metadata.

        Returns None if resource lacks required fields (kind, metadata.name)
        """
        kind = doc.get("kind")
        metadata = doc.get("metadata", {})
        name = metadata.get("name")

        if not kind:
            if self.verbose:
                print(f"Warning: Skipping resource without 'kind' field", file=sys.stderr)
            return None

        if not name:
            if self.verbose:
                print(f"Warning: Skipping {kind} resource without 'metadata.name'", file=sys.stderr)
            return None

        # Filter by kind if specified
        if self.kinds and kind.lower() not in self.kinds:
            if self.verbose:
                print(f"Skipping {kind}/{name} (not in --kind filter)")
            self.stats['skipped'] += 1
            return None

        # Build filename components
        parts = [self.sanitize_filename(kind.lower())]

        if self.include_namespace:
            namespace = metadata.get("namespace")
            if namespace:
                parts.append(self.sanitize_filename(namespace))

        parts.append(self.sanitize_filename(name))

        return "_".join(parts) + ".yaml"

    def write_resource(self, doc: Dict, filename: str) -> bool:
        """
        Write a single resource document to file.

        Returns True on success, False on error.
        """
        filepath = self.output_dir / filename

        # Check for existing file
        if filepath.exists() and not self.force:
            print(f"Error: {filepath} already exists (use --force to overwrite)", file=sys.stderr)
            self.stats['errors'] += 1
            return False

        if self.dry_run:
            print(f"Would write: {filepath}")
            return True

        try:
            with open(filepath, 'w') as outfile:
                self.yaml.dump(doc, outfile)

            if self.verbose:
                kind = doc.get('kind', 'Unknown')
                name = doc.get('metadata', {}).get('name', 'unknown')
                print(f"Saved {kind}/{name} → {filepath}")
            else:
                print(f"Saved {filepath}")

            self.stats['written'] += 1
            return True

        except IOError as e:
            print(f"Error: Failed to write {filepath}: {e}", file=sys.stderr)
            self.stats['errors'] += 1
            return False

    def process_file(self, input_file: str) -> int:
        """
        Process multi-document YAML file and extract resources.

        Returns exit code: 0 on success, 1 on errors
        """
        input_path = Path(input_file)

        # Validate input file
        if not input_path.exists():
            print(f"Error: File '{input_file}' not found", file=sys.stderr)
            return 1

        if not input_path.is_file():
            print(f"Error: '{input_file}' is not a file", file=sys.stderr)
            return 1

        # Create output directory if needed
        if not self.dry_run and not self.output_dir.exists():
            try:
                self.output_dir.mkdir(parents=True, exist_ok=True)
                if self.verbose:
                    print(f"Created output directory: {self.output_dir}")
            except OSError as e:
                print(f"Error: Failed to create directory {self.output_dir}: {e}", file=sys.stderr)
                return 1

        # Parse and process YAML documents
        try:
            with open(input_path, 'r') as infile:
                documents = list(self.yaml.load_all(infile))
        except YAMLError as e:
            print(f"Error: Failed to parse YAML: {e}", file=sys.stderr)
            return 1
        except IOError as e:
            print(f"Error: Failed to read {input_file}: {e}", file=sys.stderr)
            return 1

        if not documents:
            print(f"Warning: No documents found in {input_file}", file=sys.stderr)
            return 0

        # Process each document
        for doc in documents:
            self.stats['processed'] += 1

            # Skip empty documents
            if doc is None:
                if self.verbose:
                    print("Skipping empty document")
                self.stats['skipped'] += 1
                continue

            # Validate document is a dict
            if not isinstance(doc, dict):
                if self.verbose:
                    print(f"Warning: Skipping non-dict document: {type(doc)}", file=sys.stderr)
                self.stats['skipped'] += 1
                continue

            # Generate filename and write
            filename = self.generate_filename(doc)
            if filename:
                self.write_resource(doc, filename)
            else:
                self.stats['skipped'] += 1

        return 1 if self.stats['errors'] > 0 else 0

    def print_summary(self):
        """Print processing statistics"""
        print("\n" + "="*60)
        print("Summary:")
        print(f"  Processed:  {self.stats['processed']} documents")
        print(f"  Written:    {self.stats['written']} files")
        print(f"  Skipped:    {self.stats['skipped']} documents")
        print(f"  Errors:     {self.stats['errors']}")
        print("="*60)


def parse_arguments():
    """Parse and validate command-line arguments"""
    parser = argparse.ArgumentParser(
        description='Extract individual Kubernetes/OpenShift resources from multi-document YAML files',
        epilog='Example: %(prog)s stack.yaml -o extracted/ -n --verbose',
        formatter_class=argparse.RawDescriptionHelpFormatter
    )

    parser.add_argument(
        'input_file',
        help='Input YAML manifest file'
    )

    parser.add_argument(
        '-o', '--output-dir',
        default='.',
        metavar='DIR',
        help='Output directory for extracted files (default: current directory)'
    )

    parser.add_argument(
        '-n', '--include-namespace',
        action='store_true',
        help='Include namespace in filename: {kind}_{namespace}_{name}.yaml'
    )

    parser.add_argument(
        '-k', '--kind',
        action='append',
        metavar='KIND',
        help='Extract only specified resource kinds (can be used multiple times). Example: -k Service -k ConfigMap'
    )

    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would be extracted without writing files'
    )

    parser.add_argument(
        '-v', '--verbose',
        action='store_true',
        help='Show detailed processing information'
    )

    parser.add_argument(
        '-f', '--force',
        action='store_true',
        help='Overwrite existing files without prompting'
    )

    parser.add_argument(
        '--summary',
        action='store_true',
        help='Print processing summary at the end'
    )

    return parser.parse_args()


def main():
    """Main entry point"""
    args = parse_arguments()

    # Create decoupler instance
    decoupler = YAMLDecoupler(
        output_dir=args.output_dir,
        include_namespace=args.include_namespace,
        dry_run=args.dry_run,
        verbose=args.verbose,
        force=args.force,
        kinds=set(args.kind) if args.kind else None
    )

    # Process the file
    exit_code = decoupler.process_file(args.input_file)

    # Print summary if requested
    if args.summary or args.verbose:
        decoupler.print_summary()

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
