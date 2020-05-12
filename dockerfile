FROM ubuntu:18.04 as base
MAINTAINER Shyaman Jayasundara <shayaman321@gmail.com>

RUN apt-get update -y && \
    DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends git wget make ca-certificates \
    bison flex perl python3 libxml2-dev gcc g++ \ 
    qt5-default libwebkitgtk-3.0-0 default-jre libgtk2.0-0 libqt5opengl5-dev && \
    apt-get clean && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.6 1 && \
    rm -rf /var/lib/apt/lists/*

FROM base as builder

WORKDIR /root

RUN wget https://github.com/omnetpp/omnetpp/releases/download/omnetpp-5.4.1/omnetpp-5.4.1-src-linux.tgz \
        -O omnetpp-src-linux.tgz --progress=dot:giga && \
         tar xf omnetpp-src-linux.tgz && rm omnetpp-src-linux.tgz
RUN mv omnetpp-5.4.1 omnetpp
WORKDIR /root/omnetpp
ENV PATH /root/omnetpp/bin:$PATH
# remove unused files and build
RUN ./configure WITH_OSG=no WITH_OSGEARTH=no WITH_TKENV=no WITH_QTENV=no && \
    make -j $(nproc) MODE=release base && \
    rm -r doc out test samples misc config.log config.status


FROM base

RUN mkdir -p /root/omnetpp
WORKDIR /root/omnetpp
COPY --from=builder /root/omnetpp/ .
ENV PATH /root/omnetpp/bin:$PATH
RUN chmod 775 /root/ && \
    mkdir -p /root/models && \
    chmod 775 /root/models && \
    touch ide/error.log && chmod 666 ide/error.log && \
    mv bin/omnetpp bin/omnetpp.bak && \
    sed 's!$IDEDIR/../samples!/root/models!' bin/omnetpp.bak >bin/omnetpp && \
    rm bin/omnetpp.bak && chmod +x bin/omnetpp
WORKDIR /root/models
RUN echo 'PS1="omnetpp-gui-5.4.1:\w\$ "' >> /root/.bashrc && chmod +x /root/.bashrc && \
    touch /root/.hushlogin
ENV HOME=/root/
CMD /bin/bash --init-file /root/.bashrc

RUN wget https://github.com/inet-framework/inet/releases/download/v3.6.7/inet-3.6.7-src.tgz \
         -O inet.tgz --progress=dot:giga && \
         tar xf inet.tgz && rm inet.tgz

COPY src/MACBase.cc src/MACBase.h /root/models/inet/src/inet/linklayer/base/
COPY src/EtherMAC.cc src/EtherMAC.ned src/EtherMACFullDuplex.cc src/EtherMACFullDuplex.ned \ 
        /root/models/inet/src/inet/linklayer/ethernet/
        
# RUN cd inet && make makefiles && \
#     make MODE=release -j2 all && \
#     rm -r examples out tests tutorials misc WHATSNEW

RUN git clone https://github.com/danhld/openflow.git

