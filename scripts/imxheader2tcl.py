#! /usr/bin/env python
#
# This file is part of Xvisor Build Environment.
# Copyright (C) 2015 Institut de Recherche Technologique SystemX
# Copyright (C) 2015 OpenWide
# All rights reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this Xvisor Build Environment. If not, see
# <http://www.gnu.org/licenses/>.
#
# @file scripts/imxheader2tcl.py

#
# This script has been done to read an imx boot file, extract
# DCD information (i.e. DDR and clock initializations), and dump it
# in TCL for OpenOCD.
#

from sys import argv, stderr
from struct import unpack
from os import path
from collections import namedtuple
from traceback import print_exc

SIZEOFINT = 4


class IMX_IMG_Reader:
    imgfile = None
    ivt = None
    dcd_header = None
    Header = None
    dcd_cmdseq = []

    def __init__(self, imgpath):
        self.imgfile = open(imgpath, 'rb')
        self.Header = namedtuple('Header', 'tag length version')
        self.WriteCmd = namedtuple('WriteCmd', 'bytes mask set oplist')
        self.WriteOp = namedtuple('WriteOp', 'address value')


    def __header_get(self):
        data = self.imgfile.read(SIZEOFINT)
        return self.Header._make(unpack('>BHB', data))


    def ivt_check(self):
        if not self.ivt:
            self.ivt_read()

        if not getattr(self.ivt, 'tag') == 0xd1:
            print("IVT incorrect header tag (0x%x vs 0xd1)" %
                  getattr(self.ivt, 'tag'))
            return False

        if not getattr(self.ivt, 'length') == 32:
            print("IVT incorrect header length (0x%x vs 0x20)" %
                   getattr(self.ivt, 'length'))
            return False

        version = getattr(self.ivt, 'version')
        if version != 0x40 and version != 0x41:
            print("IVT incorrect version field (0x%x)" % version)
            return False

        if getattr(self.ivt, 'reserved1') != 0:
            print("IVT incorrect reserved field 1 (0x%x)" %
                  getattr(self.ivt, 'reserved1'))
            return False
        if getattr(self.ivt, 'reserved2') != 0:
            print("IVT incorrect reserved field 2 (0x%x)" %
                  getattr(self.ivt, 'reserved2'))
            return False

        if version == 0x40:
            print("Image version 0x40")
        elif version == 0x41:
            print("Image version 0x41")

        return True


    def ivt_read(self):
        self.imgfile.seek(0, 0)
        Ivt = namedtuple('IVT', 'tag length version entry, reserved1, dcd, ' \
                         'bootdata, selfaddr, csf, reserved2')
        header = self.__header_get()
        data = self.imgfile.read(SIZEOFINT * 7)
        self.ivt = Ivt._make(header + unpack("<IIIIIII", data))


    def dcd_header_check(self, offset):
        if not self.ivt:
            self.dcd_read()

        if getattr(dcd, 'tag') != 0xd2:
            print("DCD incorrect tag (0x%x vs 0xd2)" % getattr(dcd, 'tag'))
            return False

        version = getattr(dcd, 'version')
        # Check also the version 0x40
        if version != 0x40 and version != 0x41:
            print("DCD incorrect version (0x%x vs 0x41)" %
                  getattr(dcd, 'version'))
            return False
        return True


    def __dcd_cmd_write(self, header):
        length = getattr(header, 'length')

        # We already read 4 bytes, the header
        length -= 4
        if length % 8:
            print("The write command data length is not correct (0x%x)" %
                  length)
            return None
        data = self.imgfile.read(length)

        cmdlist = []
        pos = 0
        # Read the address and the value/mask at once
        while pos < length:
            cmd = self.WriteOp._make(unpack('>II', data[pos:pos + 8]))
            cmdlist.append(cmd)
            pos += 8

        param = getattr(header, 'version')
        nbbytes = param & 0x7
        maskbit = param & (1 << 3)
        setbit = param & (1 << 4)
        if nbbytes != 1 and nbbytes != 2 and nbbytes != 4:
            print("Write cmd: Invalid number of bytes")
            return

        cmd = self.WriteCmd(nbbytes, maskbit, setbit, cmdlist)
        self.dcd_cmdseq.append(cmd)


    def __dcd_cmd_check(self, header):
        print("Command check unmanaged yet")
        return None


    def __dcd_cmd_nop(self, header):
        print("Command nop unmanaged yet")
        return None


    def __dcd_cmd_unlock(self, header):
        print("Command unlock unmanaged yet")
        return None


    def dcd_read(self):
        if not self.ivt:
            self.ivt_read()
        self.dcd_cmdseq = []

        offset = getattr(self.ivt, 'dcd') - getattr(self.ivt, 'selfaddr')
        self.imgfile.seek(offset, 0)
        self.dcd_header = self.__header_get()

        length = getattr(self.dcd_header, 'length')
        # We already read 4 bytes, the header
        length -= SIZEOFINT
        pos = 0
        while length > 0:
            cmd_header = self.__header_get()
            tag = getattr(cmd_header, 'tag')
            if tag == 0xCC:
                self.__dcd_cmd_write(cmd_header)
            elif tag == 0xCF:
                self.__dcd_cmd_check(cmd_header)
            elif tag == 0xCF:
                self.__dcd_cmd_check(cmd_header)
            elif tag == 0xCF:
                self.__dcd_cmd_check(cmd_header)
            else:
                print("Unknown command", hex(tag))
            length -= getattr(cmd_header, 'length')
        return self.dcd_cmdseq


    def __dcd_cmd_write_dump(self, cmd):
        nbbytes = getattr(cmd, 'bytes')
        setbit = getattr(cmd, 'set')
        maskbit = getattr(cmd, 'mask')
        print("%d-bytes write sequence (%d %d)" %
              (getattr(cmd, 'bytes'), setbit, maskbit))
        if not maskbit:
            op = '='
        elif setbit:
            op = '|='
        else:
            op = '~='
        for cmdop in getattr(cmd, 'oplist'):
            address = getattr(cmdop, "address")
            address &= (1 << (nbbytes * 8)) - 1
            print("*0x%08x %s 0x%08x" % (address, op,
                                         getattr(cmdop, "value")))


    def dcd_dump(self):
        for cmd in self.dcd_cmdseq:
            if isinstance(cmd, self.WriteCmd):
                try:
                    self.__dcd_cmd_write_dump(cmd)
                except:
                    print("Error in commands:")
                    print_exc(2)


    def __dcd_cmd_write_dump2tcl(self, cmd):
        nbbytes = getattr(cmd, 'bytes')
        setbit = getattr(cmd, 'set')
        maskbit = getattr(cmd, 'mask')

        if maskbit:
            stderr.print("Operation not managed yet")
            return

        for cmdop in getattr(cmd, 'oplist'):
            address = getattr(cmdop, "address")
            address &= (1 << (nbbytes * 8)) - 1
            value = getattr(cmdop, "value")
            print("mww phys 0x%08x 0x%08x" % (address, value))


    def dcd_dump2tcl(self):
        for cmd in self.dcd_cmdseq:
            if isinstance(cmd, self.WriteCmd):
                try:
                    self.__dcd_cmd_write_dump2tcl(cmd)
                except:
                    print("Error in commands:")
                    print_exc(2)


def main(argv):
    if len(argv) < 2:
        print("Missing file argument")
        return -1

    try:
        reader = IMX_IMG_Reader(argv[1])
        reader.ivt_read()
        reader.dcd_read()
        reader.dcd_dump2tcl()
    except IOError as e:
        print("I/O error({0}): {1}".format(e.errno, e.strerror))

main(argv)
