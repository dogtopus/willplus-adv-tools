#!/usr/bin/env python

import sys

if len(sys.argv) < 3:
	print('Usage: wsc2scr <Input File> <Output File> [-r]')
	sys.exit(1)

if len(sys.argv) > 3 and sys.argv[3] == '-r':
    reverse = True
else:
    reverse = False

with open(sys.argv[1], 'rb') as fin, open(sys.argv[2], 'wb') as fout:
    tmp = bytearray(1)
    while fin.readinto(tmp) == len(tmp):
        if reverse:
            tmp[0] = ((tmp[0] << 2) | (tmp[0] >> 6)) & 0xff
        else:
            tmp[0] = ((tmp[0] >> 2) | (tmp[0] << 6)) & 0xff
        fout.write(tmp)
