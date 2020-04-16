#!/usr/bin/env python3

# WillPlus Image Pack (WIP) reader
# The format is used by older (200x era) WillPlus VN engine.
# Special thanks to: asmodean's exbelarc (http://asmodean.reverse.net/pages/exbelarc.html).
# Although the source release is incomplete and didn't compile, it provides all the information necessary for me to write my own (and improved) parser.

import argparse
import ctypes
import io
import itertools
import string
import warnings
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
    p.add_argument('-o', '--output', help='Output file (use {index} for inserting indices for multi-object images and {offset} for inserting object offset).')
    # TODO apply mask and flattern all objects onto one image (good for preview)
    #p.add_argument('-f', '--flattern', action='store_true', help='Draw all objects on a single image.')
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
    def _read_object_header(wipf, header):
        for _ in range(header.objects):
            objhdr = WIPFObjectHeader()
            if wipf.readinto(objhdr) == ctypes.sizeof(objhdr):
                yield objhdr
            else:
                raise EOFError('Unexpected EOF while reading object headers')
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
    eos = False

    # Bitstream format: ffffffff [llllllll|iiiiiiiiiiiidddd]{1-8} ...
    # f: Flag (1: literal, 0: look-back)
    # l: Literal bit. Copy to the output
    # i: Look-back index
    # d: Look-back distance/length (with THRESHOLD of 2 so it's evaluated as (raw_distance_bits + 2))
    # The stream seems to terminate with a look-back with i=0 and d=0
    # All data are in big endian byte order
    while not eos:
        if compressed_io.readinto(flags_buf) != 1:
            raise EOFError('Unexpected end-of-stream when decompressing data.')
        flags = flags_buf[0]
        for _ in range(8):
            if flags & 1:
                # literal
                byte = compressed_io.read(1)
                if len(byte) != 1:
                    raise EOFError('Unexpected end-of-stream when decompressing data.')
                decompressed.write(byte)
                window[index] = byte[0]
                index = (index + 1) % len(window)
            else:
                # look-back
                inst = compressed_io.read(2)
                if len(inst) != 2:
                    raise EOFError('Unexpected end-of-stream when decompressing data.')
                inst = int.from_bytes(inst, 'big')
                look_back_index, look_back_len = ((inst >> 4) & 0xfff), ((inst & 0xf) + 2)
                # End-of-stream marker?
                if look_back_index == 0 and look_back_len == 2:
                    eos = True
                    break
                for _ in range(look_back_len):
                    byte = window[look_back_index]
                    decompressed.write(byte.to_bytes(1, 'big'))
                    window[index] = byte
                    index = (index + 1) % len(window)
                    look_back_index = (look_back_index + 1) % len(window)
            flags >>= 1
    return decompressed.getvalue()

def load_wipf(wipf, filename=None, info_only=False):
    header, object_headers = read_header(wipf)

    # Output information
    if filename is not None:
        print(f'Filename: {filename}')
    dump_info(header, object_headers)

    if info_only:
        return None

    if header.depth not in (8, 24):
        raise ValueError(f'Cannot infer image mode from unexpected bit-depth {header.depth}')

    result = {'header': header, 'object_headers': [], 'objects': []}
    for objhdr in object_headers:
        result['object_headers'].append(objhdr)
        if header.depth == 8:
            # RGBX?
            palette = wipf.read(256 * 4)
        else:
            palette = None
        decompressed_buffer = wip_lzss_decompress(wipf.read(objhdr.size))
        mv = memoryview(decompressed_buffer)
        pixels = objhdr.dimension.x * objhdr.dimension.y
        expected_bytes = pixels * (header.depth // 8)
        assert expected_bytes == len(decompressed_buffer), f'Unexpected size of decompressed object (expecting {expected_bytes}, got {len(decompressed_buffer)})'
        if header.depth == 24: # RGB
            channels = tuple(Image.frombuffer('L', (objhdr.dimension.x, objhdr.dimension.y), mv[pixels*i:pixels*(i+1)], 'raw', 'L', 0, 1) for i in reversed(range(3)))
            result['objects'].append(Image.merge('RGB', channels))
        elif header.depth == 8: # P
            image = Image.frombuffer('P', (objhdr.dimension.x, objhdr.dimension.y), mv, 'raw', 'P', 0, 1)
            image.putpalette(palette, 'RGBX')
            result['objects'].append(image)
    return result

def apply_mask(wipf, mask):
    wipf_objs = wipf['objects']
    mask_objs = mask['objects']
    if len(wipf_objs) != len(mask_objs):
        raise ValueError('WIPF and mask contain diffeent numbers of entries.')
    for baseobj, maskobj in zip(wipf_objs, mask_objs):
        baseobj.putalpha(maskobj.convert('L'))

if __name__ == '__main__':
    p, args = parse_args()
    if args.output is None:
        with open(args.wipf, 'rb') as wipf:
            load_wipf(wipf, args.wipf, True)
    else:
        with open(args.wipf, 'rb') as wipf:
            image = load_wipf(wipf, args.wipf)
        if args.mask is not None:
            with open(args.mask, 'rb') as wipf:
                mask = load_wipf(wipf, args.mask)
                # TODO apply mask to image
                apply_mask(image, mask)
        available_output_fields = tuple(f[1] for f in string.Formatter().parse(args.output))
        has_offset = 'offset' in available_output_fields
        has_index = 'index' in available_output_fields
        if len(image['objects']) > 1 and not has_index:
            raise RuntimeError('Refusing to write multiple objects to the same output file.')
        for index, objpair in enumerate(zip(image['object_headers'], image['objects'])):
            objhdr, obj = objpair
            if (objhdr.position.x != 0 or objhdr.position.y != 0) and not has_offset:
                warnings.warn(RuntimeWarning('{offset} not specified on output objects with offset. This information will be lost.'))
            output_fields = {}
            if has_index:
                output_fields['index'] = index
            if has_offset:
                output_fields['offset'] = f'{objhdr.position.x:d}x{objhdr.position.y:d}'
            obj.save(args.output.format(**output_fields))
