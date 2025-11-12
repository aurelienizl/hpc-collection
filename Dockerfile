
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    ca-certificates \
    gfortran \
    libcurl4-openssl-dev \
 && rm -rf /var/lib/apt/lists/*

# ----------------------------
# Build OpenMPI
# ----------------------------
WORKDIR /build

RUN wget -O openmpi.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/official/openmpi/openmpi-5.0.7.tar.gz" \
 && tar -xzf openmpi.tar.gz \
 && rm openmpi.tar.gz \
 && cd openmpi-5.0.7 \
 && ./configure --prefix=/hpc/openmpi --with-pmix=internal \
 && make -j"$(nproc)" \
 && make install

# ----------------------------
# Build OpenBLAS
# ----------------------------
WORKDIR /build

RUN wget -O openblas.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/official/openblas/openblas-0.3.29.tar.gz" \
 && tar -xzf openblas.tar.gz \
 && rm openblas.tar.gz \
 && cd openblas-0.3.29 \
 && make -j"$(nproc)" all \
 && mkdir -p /hpc/openblas \
 && make PREFIX=/hpc/openblas install 

# ----------------------------
# Build HPL
# ----------------------------
WORKDIR /build

RUN wget -O hpl.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/dev/official/hpl/hpl-2.3.tar.gz" \
 && tar -xzf hpl.tar.gz && rm hpl.tar.gz \
 && mv hpl-2.3 ~/hpl \
 && cd ~/hpl/setup \
 && sh make_generic \
 && cp Make.UNKNOWN ../Make.linux \
 && cd .. \
 && sed -i \
   -e 's/^ARCH[[:space:]]*=.*/ARCH         = linux/' \
   -e 's|^TOPdir[[:space:]]*=.*|TOPdir       = $(HOME)/hpl|' \
   -e 's|^MPdir[[:space:]]*=.*|MPdir        = /hpc/openmpi|' \
   -e 's|^MPinc[[:space:]]*=.*|MPinc        = -I$(MPdir)/include|' \
   -e 's|^MPlib[[:space:]]*=.*|MPlib        = -L$(MPdir)/lib -lmpi|' \
   -e 's|^LAdir[[:space:]]*=.*|LAdir        = /hpc/openblas|' \
   -e 's|^LAinc[[:space:]]*=.*|LAinc        =|' \
   -e 's|^LAlib[[:space:]]*=.*|LAlib        = $(LAdir)/lib/libopenblas.a -lm -lpthread -lgfortran|' \
   -e 's|^CC[[:space:]]*=.*|CC           = $(MPdir)/bin/mpicc|' \
   -e 's|^LINKER[[:space:]]*=.*|LINKER       = $(CC)|' \
   Make.linux \
 && make arch=linux

# ----------------------------
# Build NetPIPE
# ----------------------------
WORKDIR /build

RUN wget -O netpipe.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/official/netpipe/netpipe-3.7.2.tar.gz" \
 && tar -xzf netpipe.tar.gz && rm netpipe.tar.gz \
 && cd NetPIPE-3.7.2 \
 && export PATH="/hpc/openmpi/bin:${PATH}" \
 && make mpi


# ----------------------------
# Build HPCC
# ----------------------------
WORKDIR /build

RUN wget -O hpcc.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/custom/hpcc/hpcc-a1.5.0.tar.gz" \
 && tar -xzf hpcc.tar.gz && rm hpcc.tar.gz \
 && cd hpcc-a1.5.0 \
 && make arch=linux

# ----------------------------
# Build Llama.cpp 
# See: https://gitlab.informatik.uni-halle.de/ambcj/llama.cpp/-/tree/133d99c59980139f5bb75922c8b5fca67d7ba9b8/examples/rpc
# ----------------------------
WORKDIR /build

RUN wget -O llama.tar.gz "https://github.com/ggml-org/llama.cpp/archive/refs/tags/b7035.tar.gz" \
 && tar -xzf llama.tar.gz && rm llama.tar.gz \
 && cd llama.cpp-b7035 \
 && cmake -B build -DLLAMA_RPC=ON \
 && cmake --build build --config Release -- -j$(nproc)
