# Dockerfile for reproducible shim build
# Adapted from Proxmox shim-review request
FROM debian:bookworm-20250610

# Update package lists and install build dependencies
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates wget git

# Clone shim-review repository for comparison
RUN git clone https://github.com/truenas/shim-review.git
WORKDIR /shim-review
RUN git checkout truenas/bookworm
WORKDIR /

# Download and verify upstream shim source
RUN wget https://github.com/rhboot/shim/releases/download/16.0/shim-16.0.tar.bz2
RUN echo "d503f778dc75895d3130da07e2ff23d2393862f95b6cd3d24b10cbd4af847217  shim-16.0.tar.bz2" >SHA256SUM
RUN sha256sum -c SHA256SUM

# Prepare source archive (Debian naming convention)
RUN mv shim-16.0.tar.bz2 shim_16.0+truenas.orig.tar.bz2

# Clone TrueNAS shim repository and build
RUN git clone https://github.com/truenas/shim-unsigned /shim-truenas
WORKDIR /shim-truenas
RUN git checkout stable/bookworm

# Install build dependencies and build package
RUN apt-get build-dep -y .
RUN dpkg-buildpackage -us -uc

# Verify build output against reference
WORKDIR /
RUN hexdump -Cv /shim-truenas/shimx64.efi >build
RUN hexdump -Cv /shim-review/shimx64.efi >orig
RUN diff -u orig build || (echo "Build verification failed!" && exit 1)
RUN sha256sum /shim-truenas/shim*.efi /shim-review/shim*.efi
