# Use an official Ubuntu as a base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    wget \
    libxerces-c-dev \
    libhdf5-serial-dev \
    python3 \
    python3-pip \
    curl \
    libzmq3-dev \
    libboost-all-dev \
    gfortran \
    libncurses5-dev \
    libncursesw5-dev

    
RUN apt-get install libc6-dev-arm64-cross -y

# Install HELICS
RUN git clone --branch main https://github.com/GMLC-TDC/HELICS /opt/helics
WORKDIR /opt/helics
RUN git submodule update --init --recursive
RUN mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make && make install

# Install jsoncpp
RUN git clone https://github.com/open-source-parsers/jsoncpp.git /opt/jsoncpp
WORKDIR /opt/jsoncpp/build
RUN cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make && make install

# Clone GridLAB-D repository
RUN git clone https://github.com/gridlab-d/gridlab-d.git /opt/gridlabd

# Ensure that submodules are initialized
WORKDIR /opt/gridlabd
RUN git submodule update --init --recursive

# Remove jsoncpp_lib references in CMakeLists.txt
RUN sed -i '/add_subdirectory(third_party\/jsoncpp_lib)/d' /opt/gridlabd/CMakeLists.txt && \
    sed -i '/get_target_property(jsoncpp_lib/d' /opt/gridlabd/CMakeLists.txt && \
    sed -i '/target_link_libraries(jsoncpp_lib/d' /opt/gridlabd/CMakeLists.txt

# Create a build directory and set it as the working directory
RUN mkdir /opt/gridlabd/cmake-build
WORKDIR /opt/gridlabd/cmake-build

# Configure and build GridLAB-D with HELICS
RUN cmake -DCMAKE_INSTALL_PREFIX=/opt/gridlabd/cmake-build/ \
          -DCMAKE_BUILD_TYPE=Release \
          -DGLD_USE_HELICS=ON \
          -DGLD_HELICS_DIR=/opt/helics/config/ \
          ..
RUN make -j8 && make install

# Set PATH
ENV PATH="/opt/gridlabd/cmake-build/bin:${PATH}"

# Verify installation of GridLAB-D and HELICS
RUN gridlabd --version && helics_broker --version

# Default command to run GridLAB-D
CMD ["gridlabd"]
