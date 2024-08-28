#run ubuntu
FROM ubuntu:22.04 as builder

WORKDIR /root/develop

#install all prerequisites
RUN apt update && apt install -y \
  libzmq5-dev python3-dev \
  libboost-all-dev \
  build-essential swig cmake git

#clone git repository 
RUN git clone --recurse-submodules \
  https://github.com/GMLC-TDC/HELICS.git helics

WORKDIR /root/develop/helics

#cmake build 
RUN cmake \
  -DCMAKE_INSTALL_PREFIX=/helics \
  -DCMAKE_BUILD_TYPE=Release \
  -B build

RUN cmake --build build -j -t install


FROM ubuntu:22.04

COPY --from=builder /helics /usr/local/

ENV PYTHONPATH /usr/local/python

# Python must be installed after the PYTHONPATH is set above for it to
# recognize and import libhelicsSharedLib.so.
RUN apt update && apt install -y --no-install-recommends \
  libboost-filesystem1.74.0 libboost-program-options1.74.0 \
  libboost-test1.74.0 libzmq5 pip python3-dev

#helics library in python and CLI to run commands
RUN pip install helics
RUN pip install helics[cli]

#use all the folders in the 'helics-docker' folder 
COPY . /root/develop/helics/

WORKDIR /root/develop/helics

#final run command - helics run
CMD ["helics", "run", "--path=fundamental_default_runner.json"] 