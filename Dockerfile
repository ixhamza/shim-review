# Dockerfile for reproducible shim build
FROM debian:trixie-20260223

# Update package lists and install build dependencies
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ca-certificates wget git

# Clone shim-review repository for comparison
RUN git clone https://github.com/truenas/shim-review.git
WORKDIR /shim-review
RUN git checkout truenas-shim-amd64-20260303
WORKDIR /

# Download and verify upstream shim source
RUN wget https://github.com/rhboot/shim/releases/download/16.1/shim-16.1.tar.bz2
RUN echo "46319cd228d8f2c06c744241c0f342412329a7c630436fce7f82cf6936b1d603  shim-16.1.tar.bz2" >SHA256SUM
RUN sha256sum -c SHA256SUM

# Prepare source archive (Debian naming convention)
RUN mv shim-16.1.tar.bz2 shim_16.1+truenas.orig.tar.bz2

# Clone TrueNAS shim repository and build
RUN git clone https://github.com/truenas/shim-unsigned /shim-truenas
WORKDIR /shim-truenas
RUN git checkout master

# Install build dependencies and build package
RUN apt-get build-dep -y .
RUN DEB_BUILD_OPTIONS='reproducible=+fixfilepath' dpkg-buildpackage -us -uc

# Verify build output against reference
WORKDIR /
RUN hexdump -Cv /shim-truenas/shimx64.efi >build
RUN hexdump -Cv /shim-review/shimx64.efi >orig
RUN diff -u orig build || (echo "Build verification failed!" && exit 1)
RUN sha256sum /shim-truenas/shim*.efi /shim-review/shim*.efi
