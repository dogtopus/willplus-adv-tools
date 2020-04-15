#!/usr/bin/env python3

# WillPlus Image Pack (WIP) reader
# The format is used by older (200x era) WillPlus VN engine.

import argparse
import ctypes
import io
import itertools
from PIL import Image

WIPF_MAGIC = b'WIPF'

class WIPFHeader(ctypes.LittleEndianStructure):
    _pack_ = 1
    _fields_ = (
        ('magic', 4 * ctypes.c_char),
        ('objects', ctypes.c_uint16),
        ('depth', ctypes.c_uint16),
    )

class WIPFVec2(ctypes.LittleEndianStructure):
    _pack_ = 1
    _fields_ = (
        ('x', ctypes.c_uint32),
        ('y', ctypes.c_uint32),
    )

class WIPFObjectHeader(ctypes.LittleEndianStructure):
    _pack_ = 1
    _fields_ = (
        ('dimension', WIPFVec2),
        ('position', WIPFVec2),
        # layer?
        ('unk', ctypes.c_uint32),
        ('size', ctypes.c_uint32),
    )

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('wipf', help='Source WIP file.')
    p.add_argument('-o', '--output', help='Output file (use {index} for inserting indices for multi-object images).')
    p.add_argument('-f', '--flattern', action='store_true', help='Draw all objects on a single image.')
    p.add_argument('-m', '--mask', help='Read a mask file and use it as alpha channel.')
    return p, p.parse_args()

def dump_info(header, object_headers):
    print(f'Number of Objects: {header.objects}')
    print(f'Bit-depth: {header.depth}')
    for i, objhdr in enumerate(object_headers):
        print(f'Object #{i}:')
        print(f'    Dimension: ({objhdr.dimension.x}, {objhdr.dimension.y})')
        print(f'    Position: ({objhdr.position.x}, {objhdr.position.y})')
        print(f'    Layer?: {objhdr.unk}')
        print(f'    Size: {objhdr.size}')

def read_header(wipf):
    header = WIPFHeader()
    if wipf.readinto(header) == ctypes.sizeof(header) and bytes(header.magic) == WIPF_MAGIC:
        object_headers = tuple(_read_object_header(wipf, header))
    else:
        raise RuntimeError('Not a valid WIP file.')
    return header, object_headers

def wip_lzss_decompress(compressed):
    compressed_io = io.BytesIO(compressed)
    decompressed = io.BytesIO()
    window = bytearray(4096)
    index = 1
    flags_buf = bytearray(1)

    while compressed_io.readinto(flags_buf) == 1:
        flags = flags_buf[0]
        for _ in range(8):
            if flags & 1:
                # literal
                byte = compressed_io.read(1)
                if len(byte) == 0:
                    break
                decompressed.write(byte)
                window[index] = byte[0]
                index = (index + 1) % len(window)
            else:
                # look-back
                inst = compressed_io.read(2)
                if len(inst) == 0:
                    break
                elif len(inst) != 2:
                    raise EOFError('Unexpected end-of-stream when decompressing data.')
                inst = int.from_bytes(inst, 'big')
                look_back_index, look_back_len = ((inst >> 4) & 0xfff), ((inst & 0xf) + 2)
                for _ in range(look_back_len):
                    byte = window[look_back_index]
                    decompressed.write(byte.to_bytes(1, 'big'))
                    window[index] = byte
                    index = (index + 1) % len(window)
                    look_back_index = (look_back_index + 1) % len(window)
            flags >>= 1
    return decompressed.getvalue()

def load_wipf(wipf, info_only=False):
    header, object_headers = read_header(wipf)

    # Output information
    print(f'Filename: {args.wipf}')
    dump_info(header, object_headers)

    if info_only:
        return None

    result = {'header': header, 'objects': []}
    for objhdr in object_headers:
        if header.depth == 8:
            # RGBX?
            palette = wipf.read(256 * 4)
        else:
            palette = None
        decompressed_buffer = wip_lzss_decompress(wipf.read(objhdr.size))
        mv = memoryview(decompressed_buffer)
        pixels = objhdr.dimension.x * objhdr.dimension.y
        if header.depth == 24: # RGB
            channels = tuple(Image.frombuffer('L', (objhdr.dimension.x, objhdr.dimension.y), mv[pixels*i:pixels*(i+1)], 'raw', 'L', 0, 1) for i in reversed(range(3)))
            result['objects'].append(Image.merge('RGB', channels))
        elif header.depth == 8: # P
            image = Image.frombuffer('P', (objhdr.dimension.x, objhdr.dimension.y), mv[:pixels], 'raw', 'P', 0, 1)
            image.putpalette(palette, 'RGBX')
            result['objects'].append(image)
    return result

if __name__ == '__main__':
    def _read_object_header(wipf, header):
        for _ in range(header.objects):
            objhdr = WIPFObjectHeader()
            if wipf.readinto(objhdr) == ctypes.sizeof(objhdr):
                yield objhdr
            else:
                raise EOFError('Unexpected EOF while reading object headers')

    p, args = parse_args()
    if args.output is None:
        with open(args.wipf, 'rb') as wipf:
            load_wipf(wipf, True)
    else:
        with open(args.wipf, 'rb') as wipf:
            image = load_wipf(wipf)
        if args.mask is not None:
            with open(args.mask, 'rb') as wipf:
                mask = load_wipf(wipf)
                # TODO apply mask to image
            
