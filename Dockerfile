# Use an official Ubuntu as a base image
FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages
RUN apt-get update && apt-get install -y \
    build-essential \
    libboost-all-dev \
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

# Install HELICS
RUN git clone --branch main https://github.com/GMLC-TDC/HELICS /opt/helics
WORKDIR /opt/helics
RUN git submodule update --init --recursive
RUN mkdir build && cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr/local && \
    make && make install
    
ENV PATH="/usr/local/bin:${PATH}"

# Install GridLAB-D
RUN git clone https://github.com/gridlab-d/gridlab-d.git /opt/gridlabd
WORKDIR /opt/gridlabd
RUN git submodule update --init --recursive
RUN sed -i '/add_subdirectory(third_party\/jsoncpp_lib)/d' CMakeLists.txt && \
    sed -i '/get_target_property(jsoncpp_lib/d' CMakeLists.txt && \
    sed -i '/target_link_libraries(jsoncpp_lib/d' CMakeLists.txt
RUN mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DGLD_USE_HELICS=ON \
    -DGLD_HELICS_DIR=/usr/local/helics \
    .. && \
    make -j8 && make install

# Set PATH
ENV PATH="/usr/local/bin:${PATH}"

RUN pip install helics helics[cli] numpy==1.24.4 scipy pypower
RUN pip install pyrlu

# Verify installation
RUN gridlabd --version && helics_broker --version

WORKDIR /data
COPY . .
# Default command to run GridLAB-D
#CMD ["helics", "--version"]
CMD ["helics", "run", "--path=1a_cosim_runner.json"]