ARG UBUNTU_RELEASE=22.04

# STAGE 1: Build Chisel using the Golang SDK
FROM public.ecr.aws/lts/ubuntu:${UBUNTU_RELEASE} as builder

SHELL ["/bin/bash", "-ex", "-o", "pipefail", "-c"]

WORKDIR /build/
ADD . /build/
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget dpkg-dev ca-certificates git \
    && wget https://dl.google.com/go/go1.22.4.linux-amd64.tar.gz \
    && rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.4.linux-amd64.tar.gz \
    && echo 'export PATH=$PATH:/usr/local/go/bin' >> $HOME/.profile \
    && . $HOME/.profile \
    && rm go1.22.4.linux-amd64.tar.gz \
    && ./cmd/mkversion.sh \
    && go build -o $(pwd) $(pwd)/cmd/chisel \
    && apt-get remove -y wget \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*

# STAGE 2: Create a chiselled Ubuntu base to then ship the chisel binary
FROM public.ecr.aws/lts/ubuntu:${UBUNTU_RELEASE} as installer
RUN apt-get update && apt-get install -y ca-certificates
COPY --from=builder /build/chisel /usr/bin/
WORKDIR /rootfs
RUN chisel cut --root /rootfs libc6_libs ca-certificates_data base-files_release-info

# STAGE 3: Copy the chisel binary + its chiselled Ubuntu dependencies
FROM scratch
COPY --from=installer ["/rootfs", "/"]
COPY --from=builder /build/chisel /usr/bin/
ENTRYPOINT [ "/usr/bin/chisel" ]
CMD [ "--help" ]

# *** BUILD (run from the host, not from the DevContainer) ***
# docker build . -t xanimo/chisel:latest
#
# *** USAGE ***
# mkdir chiselled
# docker run -v $(pwd)/chiselled:/opt/output --rm xanimo/chisel cut --release ubuntu-22.04 --root /opt/output/ libc6_libs ca-certificates_data
# ls -la ./chiselled
