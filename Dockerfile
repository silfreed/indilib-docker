ARG INDIVER=1.9.4

# build environment
FROM fedora:latest as base
ARG INDIVER
RUN dnf -y upgrade \
  && dnf -y install \
     curl dcraw wget git openssh redhat-lsb-core vim \
     libnova cfitsio fftw-libs-double rtl-sdr gsl \
  && dnf clean all

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
  && dnf -y install ffmpeg-devel \
  && dnf clean all

# build the application
FROM buildenv as build
ARG INDIVER
ENV FLAGS="-DCMAKE_INSTALL_PREFIX=/usr"
RUN mkdir -p /app/ \
  && curl -SL https://github.com/indilib/indi/archive/refs/tags/v${INDIVER}.tar.gz \
     | tar --strip-components=1 -xzC /app/ \
  && mkdir -p /app/build/indi-core \
  && cd /app/build/indi-core \
  && cmake $FLAGS . ../../ \
  && make \
  && make install
# build the 3rd party libraries and drivers
COPY indi-3rdparty-1.9.4-indi-celestronaux-auxproto-cstddef.patch /tmp/
RUN mkdir -p /app3p/ \
  && curl -SL https://github.com/indilib/indi-3rdparty/archive/refs/tags/v${INDIVER}.tar.gz \
     | tar --strip-components=1 -xzC /app3p/ \
  && cd /app3p/ \
  && patch -p1 < /tmp/indi-3rdparty-1.9.4-indi-celestronaux-auxproto-cstddef.patch \
  && mkdir -p /app3p/build/indi-3rdparty-lib \
  && cd /app3p/build/indi-3rdparty-lib \
  && cmake -DBUILD_LIBS=1 $FLAGS ../../. . \
  && make -j4 \
  && make install \
  && mkdir -p /app3p/build/indi-3rdparty-drv \
  && cd /app3p/build/indi-3rdparty-drv \
  && cmake $FLAGS ../../. . \
  && make -j4 \
  && make install

FROM base as app
COPY --from=build /usr/bin /usr/bin
COPY --from=build /usr/lib /usr/lib
ENTRYPOINT ["indiserver"]
CMD ["--help"]

