FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install Build Dependencies
RUN apt-get update && apt-get install -y \
    git bc bison flex libssl-dev make libc6-dev libncurses5-dev \
    crossbuild-essential-arm64 kmod cpio wget zip unzip rsync \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work

# Copy scripts
COPY builder.sh /usr/local/bin/builder.sh
COPY rt-params.config /configs/rt-params.config

RUN chmod +x /usr/local/bin/builder.sh

VOLUME ["/output"]

CMD ["/usr/local/bin/builder.sh"]