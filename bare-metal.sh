#!/bin/bash
set -e  # Exit immediately if a command exits with a non-zero status

# --- Configuration ---
# Detect actual CPU cores available to avoid overloading the embedded system
NB_CPUS=$(nproc)
BUILD_DIR="/build"
INSTALL_PREFIX="/hpc"

echo ">>> Starting Build on $(hostname)"
echo ">>> Detected ${NB_CPUS} CPU cores."

# --- 1. Install Build Dependencies ---
echo ">>> Installing System Dependencies..."
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    ca-certificates \
    gfortran \
    zlib1g-dev

# --- 2. Prepare Directories ---
echo ">>> Preparing Build Directories..."
# Create the build and install directories
sudo mkdir -p ${BUILD_DIR}
sudo mkdir -p ${INSTALL_PREFIX}
sudo mkdir -p ${INSTALL_PREFIX}/bin

# Change ownership to current user for the build process
sudo chown -R $USER:$USER ${BUILD_DIR}
sudo chown -R $USER:$USER ${INSTALL_PREFIX}

# --- 3. Build OpenMPI ---
echo ">>> Building OpenMPI..."
cd ${BUILD_DIR}
wget -O openmpi.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/official/openmpi/openmpi-5.0.7.tar.gz"
tar -xzf openmpi.tar.gz
rm openmpi.tar.gz
cd openmpi-5.0.7

./configure --prefix=${INSTALL_PREFIX}/openmpi --with-pmix=internal
make -j"${NB_CPUS}"
make install

# --- 4. Build OpenBLAS ---
echo ">>> Building OpenBLAS..."
cd ${BUILD_DIR}
wget -O openblas.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/official/openblas/openblas-0.3.29.tar.gz"
tar -xzf openblas.tar.gz
rm openblas.tar.gz
cd openblas-0.3.29

make all -j"${NB_CPUS}"
mkdir -p ${INSTALL_PREFIX}/openblas
make PREFIX=${INSTALL_PREFIX}/openblas install

# --- 5. Build NetPIPE ---
echo ">>> Building NetPIPE..."
cd ${BUILD_DIR}
wget -O netpipe.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/official/netpipe/netpipe-3.7.2.tar.gz"
tar -xzf netpipe.tar.gz
rm netpipe.tar.gz
cd NetPIPE-3.7.2

# Add OpenMPI to PATH temporarily for compilation
export PATH="${INSTALL_PREFIX}/openmpi/bin:${PATH}"
make mpi -j"${NB_CPUS}"

# Install NetPIPE Binary
cp NPmpi ${INSTALL_PREFIX}/bin/NPmpi

# --- 6. Build HPCC ---
echo ">>> Building HPCC..."
cd ${BUILD_DIR}
wget -O hpcc.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/custom/hpcc/hpcc-a1.5.0.tar.gz"
tar -xzf hpcc.tar.gz
rm hpcc.tar.gz
cd hpcc-a1.5.0

make arch=linux -j"${NB_CPUS}"

# Install HPCC Binary
cp hpcc ${INSTALL_PREFIX}/bin/hpcc

# --- 7. Cleanup & Environment Setup ---
echo ">>> Cleaning up build directory..."
sudo rm -rf ${BUILD_DIR}

# Create a source file for environment variables
# Users can run 'source /hpc/env.sh' to load the libraries
echo ">>> Adding environment variables to ~/.bashrc..."
echo "export LD_LIBRARY_PATH=\"${INSTALL_PREFIX}/openmpi/lib:${INSTALL_PREFIX}/openblas/lib:\${LD_LIBRARY_PATH}\"" >> ~/.bashrc
echo "export PATH=\"${INSTALL_PREFIX}/openmpi/bin:${INSTALL_PREFIX}/bin:\${PATH}\"" >> ~/.bashrc
echo "echo \"HPC Environment Loaded.\"" >> ~/.bashrc

echo ">>> Build Complete."
echo ">>> All binaries and libraries are located in ${INSTALL_PREFIX}"
