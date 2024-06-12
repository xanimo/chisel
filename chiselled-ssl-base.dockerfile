# chiselled-ssl-base.dockerfile

# "chisel:22.04" is our previous "chisel" image from Step 1
# we built and tagged it locally using the Docker CLI
FROM xanimo/chisel:latest as installer
WORKDIR /staging
RUN ["chisel", "cut", "--root", "/staging", \
   "base-files_base", \
   "base-files_release-info", \
   "ca-certificates_data", \
   "libc6_libs", \
   "libssl3_libs", \
   "openssl_config" ]

FROM scratch
COPY --from=installer [ "/staging/", "/" ]
