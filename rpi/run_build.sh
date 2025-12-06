#!/bin/sh
set -e

IMAGE_NAME="rpi5-rt-builder:latest"
OUTPUT_DIR="$(pwd)/build_output"

# 1. Check Docker
if ! [ -x "$(command -v docker)" ]; then
    echo 'Error: docker is not installed.' >&2
    exit 1
fi

# 2. Build Docker Image
echo "--- Building Container Image ---"
docker build -t $IMAGE_NAME .

# 3. Create Output Dir
mkdir -p "$OUTPUT_DIR"

# 4. Run Build
echo "--- Starting Kernel Build ---"
echo "Outputs will be saved to: $OUTPUT_DIR"

docker run --rm -it \
    -v "$OUTPUT_DIR":/output \
    $IMAGE_NAME

