ARG INDIVER=1.9.4

# build environment
FROM fedora:latest as base
ARG INDIVER
RUN dnf -y upgrade \
  && dnf -y install \
     curl dcraw wget git openssh redhat-lsb-core vim \
     libnova cfitsio fftw-libs-double rtl-sdr gsl

FROM base as buildenv
ARG INDIVER
RUN dnf -y install \
     cdbs cmake \
     libcurl-devel boost-devel cfitsio-devel libtiff-devel \
     libftdi-devel libgphoto2-devel gpsd-devel gsl-devel libjpeg-turbo-devel \
     libnova-devel openal-soft-devel LibRaw-devel libusb-devel rtl-sdr-devel \
     fftw-devel zlib-devel libconfuse-devel python3-devel doxygen \
     libdc1394-devel python-devel swig gcc-c++ clang \
  && dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
  && dnf -y install ffmpeg-devel 

# build the application
FROM buildenv as build
ARG INDIVER
ENV FLAGS="-DCMAKE_INSTALL_PREFIX=/usr"
RUN mkdir -p /app/\
  && curl -SL https://github.com/indilib/indi/archive/refs/tags/v${INDIVER}.tar.gz \
     | tar --strip-components=1 -xzC /app/ \
  && mkdir -p /app/build/indi-core \
  && cd /app/build/indi-core \
  && cmake $FLAGS . ../../ \
  && make \
  && make install

FROM base as app
COPY --from=build /usr .
ENTRYPOINT ["indiserver"]
CMD ["--help"]

