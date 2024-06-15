FROM xanimo/chisel:latest as installer
WORKDIR /staging
RUN [ "chisel", "cut", "--release", "ubuntu-22.04", \
    "--root", "/staging/", "libc6_libs" ]

FROM public.ecr.aws/lts/ubuntu:22.04 AS builder
WORKDIR /app

ENV TZ=Etc/UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /build
RUN apt-get update \
    && apt-get install -y curl git build-essential libtool autotools-dev automake \
        pkg-config libssl-dev libevent-dev bsdmainutils libdb5.3++-dev \
        libdb5.3++ libdb5.3-dev make python3 python-is-python3 gcc-9-multilib \
        g++-9-multilib \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 10 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 10

RUN git clone -b v1.14.7 https://github.com/dogecoin/dogecoin \
    && cd dogecoin \
    && make -j`nproc` -C depends NO_QT=1

RUN cd dogecoin \
    && ./autogen.sh \
    && ./configure \
    --prefix=`pwd`/depends/x86_64-pc-linux-gnu \
    --enable-reduce-exports \
    --enable-zmq \
    --enable-static \
    --disable-shared \
    --enable-glibc-back-compat \
    LDFLAGS="$LDFLAGS -static-libstdc++ -static-libgcc" \
    && make -j`nproc` check

RUN curl -L -O https://gist.githubusercontent.com/xanimo/595149254904abb67bfb0d5c2fb3a4f4/raw/63e2dffdd10b94dd614158edae294aa3d732cc59/configure-dogecoin.sh \
    && chmod +x configure-dogecoin.sh \
    && apt-get update \
    && apt-get install -y python3 python-is-python3 \
    && ./configure-dogecoin.sh \
    && mkdir .dogecoin \
    && mv dogecoin.conf .dogecoin/dogecoin.conf

FROM scratch
COPY --from=installer [ "/staging/", "/" ]
COPY --from=builder --chown=nobody:nogroup \
    /build/dogecoin/src/dogecoind \
    /build/dogecoin/src/dogecoin-cli /
COPY --from=builder /build/.dogecoin/dogecoin.conf /.dogecoin/dogecoin.conf
ENV PATH="$PATH:/"
EXPOSE 22555 22556 44555 44556 18444 18332
ENTRYPOINT [ "/dogecoind", "-conf=/.dogecoin/dogecoin.conf" ]
CMD [ "/dogecoind", "-conf=/.dogecoin/dogecoin.conf" ]

# docker run --rm -it $(docker build . -q -f dogecoin.dockerfile)
