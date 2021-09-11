FROM python:buster as build-image

ENV DEBIAN_FRONTEND noninteractive

# in preparation for when buster will not be supported anymore...
# RUN echo "deb http://archive.debian.org/debian buster main" > /etc/apt/sources.list
# RUN echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list

RUN apt-get -o Acquire::Check-Valid-Until=false update && \
    apt-get install -y \
        git \
        make \
        autoconf \
        python \
        curl \
        wget \
        bzip2 \
        gcc \
        g++ \
        texlive \
        texinfo \
        valgrind \
        libgl1-mesa-dev \
        libxi-dev \
        libxmu-dev \
        libxft-dev \
        libxinerama-dev \
        libxcursor-dev \
        libxfixes-dev \
        mesa-common-dev \
        libglu1-mesa-dev \
        zlib1g-dev \
        cmake \
        unzip \
        libcurl4-openssl-dev \
        emacs23-nox && \
    apt-get clean

# -----------------------
# GCC with PIC
# -----------------------

# this allows to build a static libgfortran that we can embed in dynamic libraries
ENV CFLAGS=-fPIC
ENV CXXFLAGS=-fPIC
ENV FFLAGS=-fPIC

RUN curl -L -O https://ftpmirror.gnu.org/gcc/gcc-10.3.0/gcc-10.3.0.tar.gz && tar xf gcc-10.3.0.tar.gz && cd gcc-10.3.0 && ./contrib/download_prerequisites && cd .. && mkdir gccbuild && cd gccbuild && ../gcc-10.3.0/configure -v --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu --prefix=/usr/local --enable-checking=release --enable-languages=c,c++,fortran --disable-multilib --with-pic && make -j 4 > ./build_log.txt && make install && cd .. && rm -rf gcc-10.3.0.tar.gz gcc-10.3.0 gccbuild

ENV PATH=/usr/local/bin:${PATH}
ENV LD_LIBRARY_PATH=/usr/local/lib64:${LD_LIBRARY_PATH}
ENV CC=/usr/local/bin/gcc
ENV CXX=/usr/local/bin/g++
ENV FC=/usr/local/bin/gfortran

# -----------------------
# OpenBLAS
# -----------------------

RUN git clone https://github.com/xianyi/OpenBLAS.git && cd OpenBLAS && git checkout v0.3.15 && make NUM_THREADS=8 TARGET=CORE2 && cp libopenblas_core2p-r0.3.15.a /usr/local/lib/libopenblas.a && cd .. && rm -rf OpenBLAS

# -----------------------
# Freetype
# -----------------------

RUN curl -L -O http://download.savannah.gnu.org/releases/freetype/freetype-2.10.4.tar.gz && tar zxf freetype-2.10.4.tar.gz && cd freetype-2.10.4 && ./configure --disable-shared && make && make install && cd .. && rm -rf freetype-2.10.4.tar.gz freetype-2.10.4

# -----------------------
# OpenCASCADE
# -----------------------

# RUN curl -L -o occt.tgz "http://git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=refs/tags/V7_5_1;sf=tgz" && tar xf occt.tgz && cd occt-* && mkdir build && cd build && CXXFLAGS="-fPIC -DIGNORE_NO_ATOMICS" cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRARY_TYPE=Static -DBUILD_MODULE_Draw=0 -DBUILD_MODULE_Visualization=0 -DBUILD_MODULE_ApplicationFramework=0 .. && make -j 4 && make install && cd ../.. && rm -rf occt.tgz occt-*

# OCC 7.5.1 still has the annoying bounding box bug - this is OCCT master from Feb 4 2021
RUN curl -L -o occt.tgz "http://git.dev.opencascade.org/gitweb/?p=occt.git;a=snapshot;h=4ad4054;sf=tgz" && tar xf occt.tgz && cd occt-* && mkdir build && cd build && CXXFLAGS="-fPIC -DIGNORE_NO_ATOMICS" cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRARY_TYPE=Static -DBUILD_MODULE_Draw=0 -DBUILD_MODULE_Visualization=0 -DBUILD_MODULE_ApplicationFramework=0 .. && make -j 4 && make install && cd ../.. && rm -rf occt.tgz occt-*

# -----------------------
# HDF5
# -----------------------

RUN curl -L -O https://support.hdfgroup.org/ftp/HDF5/current/src/hdf5-1.10.5.tar.gz && tar zxvf hdf5-1.10.5.tar.gz && cd hdf5-1.10.5 && ./configure --disable-shared --prefix=/usr/local && make && make install && cd .. && rm -rf hdf5-1.10.5.tar.gz hdf5-1.10.5

# -----------------------
# CGNS
# -----------------------

RUN git clone https://github.com/CGNS/CGNS.git && cd CGNS && git checkout v3.4.0 && mkdir build && cd build && cmake -DCGNS_BUILD_SHARED=0 -DCGNS_ENABLE_HDF5=1 -DHDF5_VERSION=1.10.5 .. && make && make install && cd ../.. && rm -rf CGNS

# -----------------------
# PETSc
# -----------------------

RUN curl -L -O http://ftp.mcs.anl.gov/pub/petsc/release-snapshots/petsc-3.14.4.tar.gz
RUN tar zxf petsc-3.14.4.tar.gz
ENV PETSC_DIR ${PWD}/petsc-3.14.4

ENV PETSC_ARCH real_mumps_seq
RUN cd ${PETSC_DIR} && ./configure CC=$CC CXX=$CXX FC=$FC CFLAGS=$CFLAGS CXXFLAGS=$CXXFLAGS FFLAGS=$FFLAGS --with-clanguage=cxx --with-debugging=0 --with-mpi=0 --with-mpiuni-fortran-binding=0 --download-mumps=yes --with-mumps-serial --with-shared-libraries=0 --with-x=0 --with-ssl=0 --with-scalar-type=real --with-blaslapack-lib="/usr/local/lib/libopenblas.a /usr/local/lib64/libgfortran.a /usr/local/lib64/libquadmath.a -lpthread" && make

ENV PETSC_ARCH complex_mumps_seq
RUN cd ${PETSC_DIR} && ./configure CC=$CC CXX=$CXX FC=$FC CFLAGS=$CFLAGS CXXFLAGS=$CXXFLAGS FFLAGS=$FFLAGS --with-clanguage=cxx --with-debugging=0 --with-mpi=0 --with-mpiuni-fortran-binding=0 --download-mumps=yes --with-mumps-serial --with-shared-libraries=0 --with-x=0 --with-ssl=0 --with-scalar-type=complex --with-blaslapack-lib="/usr/local/lib/libopenblas.a /usr/local/lib64/libgfortran.a /usr/local/lib64/libquadmath.a -lpthread" && make

ENV PETSC_ARCH real_mumps_seq_shared
RUN cd ${PETSC_DIR} && ./configure CC=$CC CXX=$CXX FC=$FC CFLAGS=$CFLAGS CXXFLAGS=$CXXFLAGS FFLAGS=$FFLAGS --with-clanguage=cxx --with-debugging=0 --with-mpi=0 --with-mpiuni-fortran-binding=0 --download-mumps=yes --with-mumps-serial --with-shared-libraries=1 --with-x=0 --with-ssl=0 --with-scalar-type=real --with-blaslapack-lib="/usr/local/lib/libopenblas.a /usr/local/lib64/libgfortran.a /usr/local/lib64/libquadmath.a -lpthread" && make

ENV PETSC_ARCH complex_mumps_seq_shared
RUN cd ${PETSC_DIR} && ./configure CC=$CC CXX=$CXX FC=$FC CFLAGS=$CFLAGS CXXFLAGS=$CXXFLAGS FFLAGS=$FFLAGS --with-clanguage=cxx --with-debugging=0 --with-mpi=0 --with-mpiuni-fortran-binding=0 --download-mumps=yes --with-mumps-serial --with-shared-libraries=1 --with-x=0 --with-ssl=0 --with-scalar-type=complex --with-blaslapack-lib="/usr/local/lib/libopenblas.a /usr/local/lib64/libgfortran.a /usr/local/lib64/libquadmath.a -lpthread" && make

# -----------------------
# SLEPc
# -----------------------

RUN curl -L -O https://slepc.upv.es/download/distrib/slepc-3.14.1.tar.gz
RUN tar zxf slepc-3.14.1.tar.gz
ENV SLEPC_DIR ${PWD}/slepc-3.14.1
ENV PETSC_ARCH real_mumps_seq
RUN cd ${SLEPC_DIR} && ./configure && make
ENV PETSC_ARCH complex_mumps_seq
RUN cd ${SLEPC_DIR} && ./configure && make
ENV PETSC_ARCH real_mumps_seq_shared
RUN cd ${SLEPC_DIR} && ./configure && make
ENV PETSC_ARCH complex_mumps_seq_shared
RUN cd ${SLEPC_DIR} && ./configure && make

# -----------------------
# MED
# -----------------------

RUN curl -L -O http://files.salome-platform.org/Salome/other/med-4.1.0.tar.gz && tar zxf med-4.1.0.tar.gz && cd med-4.1.0 && LIBS=-ldl ./configure --with-hdf5=/usr/local --enable-build-static --disable-shared --disable-python --disable-fortran --disable-tests --with-med_int=long && make -i install && cd .. && rm -rf med-4.1.0.tar.gz med-4.1.0

# -----------------------
# FLTK
# -----------------------

# "docker build --build-arg REBUILD_FLTK=somethingnew"
ARG REBUILD_FLTK=dummy
RUN git clone https://github.com/fltk/fltk.git && cd fltk && make makeinclude && ./configure --enable-localzlib && make -j 4 && make install && cd ../.. && rm -rf fltk

# -----------------------
# MMG
# -----------------------

RUN git clone https://github.com/MmgTools/mmg.git && cd mmg && mkdir build && cd build && cmake .. && make -j8 && make install && cd .. && rm -rf mmg

# -----------------------
# Tweaks for static
# -----------------------

# instead of modifying the build scripts, hide the shared libs we don't want to
# link to

RUN mv /usr/local/lib64/libgfortran.so /usr/local/lib64/libgfortran_DISABLED_FOR_GMSH_STATIC_LINKING.so
RUN mv /usr/local/lib64/libquadmath.so /usr/local/lib64/libquadmath_DISABLED_FOR_GMSH_STATIC_LINKING.so
RUN mv /usr/local/lib64/libgomp.so /usr/local/lib64/libgomp_DISABLED_FOR_GMSH_STATIC_LINKING.so

# -----------------------
# Minimal Gmsh library
# -----------------------

# "docker build --build-arg REBUILD_GMSH=somethingnew"
ARG REBUILD_GMSH=

RUN git clone https://gitlab.onelab.info/gmsh/gmsh.git && cd gmsh && mkdir build && cd build && cmake -DDEFAULT=0 -DENABLE_PARSER=1 -DENABLE_POST=1 -DENABLE_PLUGINS=1 -DENABLE_ANN=1 -DENABLE_BLAS_LAPACK=1 -DENABLE_BUILD_LIB=1 -DENABLE_PRIVATE_API=1 .. && make -j 2 lib && make install/fast && cd ../.. && rm -rf gmsh

VOLUME ["/etc/gitlab-runner"]
RUN useradd -ms /bin/bash geuzaine
USER geuzaine
WORKDIR /home/geuzaine
RUN mkdir -p ~/.ssh
RUN chmod 700 ~/.ssh


# AWS Lambdaに入れるための

# Define function directory
ARG FUNCTION_DIR="/function"

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}

# Copy function code
COPY app/* ${FUNCTION_DIR}

# Install the runtime interface client
RUN pip install \
        --target ${FUNCTION_DIR} \
        awslambdaric

# Multi-stage build: grab a fresh copy of the base image
FROM python:buster

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

# Copy in the build image dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "app.handler" ]
        