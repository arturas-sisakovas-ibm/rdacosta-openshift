#!/usr/bin/python3

import yaml
import os
import sys

def split_yaml_file(input_file):
    with open(input_file, 'r') as file:
        # Load the YAML content as a list of dictionaries
        docs = list(yaml.safe_load_all(file))

    for doc in docs:
        if doc is None:
            continue

        kind = doc.get("kind")
        name = doc.get("metadata", {}).get("name")

        if kind and name:
            filename = f"{kind}_{name}.yaml".lower()  # Convert to lowercase
            with open(filename, 'w') as outfile:
                yaml.dump(doc, outfile)
            print(f"Saved {filename}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python script.py <input_yaml_file>")
        sys.exit(1)

    input_file = sys.argv[1]
    if not os.path.isfile(input_file):
        print(f"Error: File '{input_file}' not found.")
        sys.exit(1)

    split_yaml_file(input_file)

