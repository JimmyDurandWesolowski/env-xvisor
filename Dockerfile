FROM ubuntu:trusty

RUN apt-get update
RUN apt-get install -y git make wget python bc
RUN apt-get install -y realpath fakeroot libtool telnet genext2fs build-essential libncurses5-dev pkg-config libusb-1.0-0-dev gcc-multilib binutils-multiarch 

RUN echo 'cd /root/env-xvisor && ./configure -n && make xvisor-uimage' > /root/make_xvisor_uimage.sh

RUN chmod +x /root/make_xvisor_uimage.sh

