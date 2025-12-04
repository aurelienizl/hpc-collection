#! /bin/sh

if ! [ -x "$(command -v docker)" ]; then
    echo 'Error: docker is not installed.' >&2
    exit 1
fi

docker build -t hpc-collection:latest .
if [ $? -ne 0 ]; then
    echo "Error: Docker build failed." >&2
    exit 1
fi

echo "HPC Collection Docker image built successfully: hpc-collection:latest"

if [ "$1" = "--it" ]; then
    docker run -it hpc-collection:latest /bin/bash
fi

echo "Exit code: $?"