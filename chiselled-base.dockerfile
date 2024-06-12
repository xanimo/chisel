# chiselled-base.dockerfile

# "chisel:22.04" is our previous "chisel" image from Step 1
# we built and tagged it locally using the Docker CLI
FROM xanimo/chisel:latest as installer

WORKDIR /staging
# Use chisel to cut out the necessary package slices from the
# chisel:22.04 image and store them in the /staging directory
RUN ["chisel", "cut", "--root", "/staging", \
    "base-files_base", \
    "base-files_release-info", \
    "ca-certificates_data", \
    "libc6_libs" ]

# Start with a scratch image as the base for our chiselled Ubuntu base image
FROM scratch
# Copy the package slices from the installer image
# to the / directory of our chiselled Ubuntu base image
COPY --from=installer [ "/staging/", "/" ]
