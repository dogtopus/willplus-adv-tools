#!/usr/bin/env python

import sys

if len(sys.argv)<3:
	print('Usage: wsc2scr <Input File> <Output File>')
	sys.exit(1)

with open(sys.argv[1], 'rb') as fin, open(sys.argv[2], 'wb') as fout:
    tmp = bytearray(1)
    while fin.readinto(tmp) == len(tmp):
        tmp[0] = ((tmp[0] >> 2) | (tmp[0] << 6)) & 0xff
        fout.write(tmp)
