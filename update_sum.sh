#!/usr/bin/env bash
# generate_sums.sh
# Compute SHA256 checksums for .tar.gz files and write them to [filename].sum

set -euo pipefail

ROOT_DIR="${1:-.}"

find "$ROOT_DIR" -type f -name '*.tar.gz' ! -name '*.sum' | while IFS= read -r file; do
    sumfile="${file}.sum"
    echo "Processing: $file"
    sha256sum "$file" | awk '{print $1}' > "$sumfile"
done

echo "All checksums generated."
