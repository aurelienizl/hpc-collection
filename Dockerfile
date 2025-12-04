FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV NB_CPUS=8

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    wget \
    ca-certificates \
    gfortran \
    zlib1g-dev \
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
 && make -j"${NB_CPUS}" \
 && make install

# ----------------------------
# Build OpenBLAS
# ----------------------------
WORKDIR /build

RUN wget -O openblas.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/official/openblas/openblas-0.3.29.tar.gz" \
 && tar -xzf openblas.tar.gz \
 && rm openblas.tar.gz \
 && cd openblas-0.3.29 \
 && make all -j"${NB_CPUS}" \
 && mkdir -p /hpc/openblas \
 && make PREFIX=/hpc/openblas install 

# ----------------------------
# Build NetPIPE
# ----------------------------
WORKDIR /build

RUN wget -O netpipe.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/official/netpipe/netpipe-3.7.2.tar.gz" \
 && tar -xzf netpipe.tar.gz && rm netpipe.tar.gz \
 && cd NetPIPE-3.7.2 \
 && export PATH="/hpc/openmpi/bin:${PATH}" \
 && make mpi -j"${NB_CPUS}"

# ----------------------------
# Build HPCC
# ----------------------------
WORKDIR /build

RUN wget -O hpcc.tar.gz "https://github.com/aurelienizl/hpc-collection/raw/refs/heads/main/custom/hpcc/hpcc-a1.5.0.tar.gz" \
 && tar -xzf hpcc.tar.gz && rm hpcc.tar.gz \
 && cd hpcc-a1.5.0 \
 && make arch=linux -j"${NB_CPUS}" 

# ----------------------------
# ----------------------------
# ----------------------------
# ----------------------------
# ----------------------------

FROM ubuntu:22.04 AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    nano \
    gfortran \
 && rm -rf /var/lib/apt/lists/*

RUN sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config
RUN echo "Host *" >> /etc/ssh/ssh_config && \
    echo "    Port 2222" >> /etc/ssh/ssh_config && \
    echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config

RUN useradd -m hpcuser
USER hpcuser

COPY --from=builder /hpc /hpc
COPY --from=builder /build/NetPIPE-3.7.2/NPmpi /hpc/bin/NPmpi
COPY --from=builder /build/hpcc-a1.5.0/hpcc /hpc/bin/hpcc

ENV LD_LIBRARY_PATH="/hpc/openmpi/lib:/hpc/openblas/lib:${LD_LIBRARY_PATH}"
ENV PATH="/hpc/openmpi/bin:${PATH}"

RUN mkdir -p /home/hpcuser/.ssh \
 && ssh-keygen -t rsa -f /home/hpcuser/.ssh/id_rsa -q -N "" \
 && cat /home/hpcuser/.ssh/id_rsa.pub >> /home/hpcuser/.ssh/authorized_keys \
 && chmod 600 /home/hpcuser/.ssh/authorized_keys

WORKDIR /home/hpcuser