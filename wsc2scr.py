#!/usr/bin/env python

import sys

if len(sys.argv)<3:
	print('Usage: wsc2scr <Input File> <Output File>')
	sys.exit(1)

try:
	fin=open(sys.argv[1],'rb')
	buffer1=fin.read()
	buffer2=''
	for i in buffer1:
		buffer2+=chr((ord(i)>>2)|((ord(i)<<6)&255))
	fout=open(sys.argv[2],'wb')
	fout.write(buffer2)
finally:
	fin.close()
	fout.close()

