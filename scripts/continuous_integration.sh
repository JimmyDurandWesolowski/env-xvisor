#! /bin/sh

#Configure env-xvisor for nitrogen6x
    cd .. && ./configure -n

#Build env
    make

#Tests
    make test xvisor-uimage

