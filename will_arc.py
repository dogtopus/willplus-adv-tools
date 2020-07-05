#!/usr/bin/env python3

import argparse
import ctypes
import os

from collections import OrderedDict


class ARCTypeEntry(ctypes.LittleEndianStructure):
    _fields_ = (
        ('name', ctypes.c_char * 4),
        ('object_list_size', ctypes.c_uint32),
        ('object_list_offset', ctypes.c_uint32),
    )
    _pack_ = 1


class ARCObjectEntryV1(ctypes.LittleEndianStructure):
    _fields_ = (
        ('name', ctypes.c_char * 9),
        ('data_size', ctypes.c_uint32),
        ('data_offset', ctypes.c_uint32),
    )
    _pack_ = 1


class ARCObjectEntryV2(ctypes.LittleEndianStructure):
    _fields_ = (
        ('name', ctypes.c_char * 13),
        ('data_size', ctypes.c_uint32),
        ('data_offset', ctypes.c_uint32),
    )
    _pack_ = 1


def parse_metadata(arc, version=1):
    if version == 1:
        ARCObjectEntry = ARCObjectEntryV1
    elif version == 2:
        ARCObjectEntry = ARCObjectEntryV2
    else:
        raise ValueError(f'Unknown version {version}.')
    metadata = OrderedDict()
    types = []
    ntypes = int.from_bytes(arc.read(4), 'little')
    for _ in range(ntypes):
        type_entry = ARCTypeEntry()
        if arc.readinto(type_entry) != ctypes.sizeof(type_entry):
            raise EOFError('Unexpected end-of-file.')
        types.append(type_entry)
    for t in types:
        objects = []
        metadata[t.name.decode('ascii')] = objects
        arc.seek(t.object_list_offset)
        for _ in range(t.object_list_size):
            object_entry = ARCObjectEntry()
            if arc.readinto(object_entry) != ctypes.sizeof(object_entry):
                raise EOFError('Unexpected end-of-file.')
            objects.append(object_entry)
    return metadata

def dump_files(arc, metadata, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    for type_, objects in metadata.items():
        for object_entry in objects:
            filename = os.path.join(output_dir, f'{object_entry.name.decode("ascii")}.{type_}')
            with open(filename, 'wb') as f:
                arc.seek(object_entry.data_offset)
                # TODO chunked copy?
                f.write(arc.read(object_entry.data_size))

def build_metadata_from_files(input_dir, version=1):
    metadata = OrderedDict()
    filename_cache = {}
    if version == 1:
        name_limit = 8
        ARCObjectEntry = ARCObjectEntryV1
    elif version == 2:
        name_limit = 12
        ARCObjectEntry = ARCObjectEntryV2
    else:
        raise ValueError(f'Unknown version {version}.')

    files = (f for f in os.listdir(input_dir) if os.path.isfile(os.path.join(input_dir, f)))
    for f in files:
        splitted = f.split('.')
        name, suffix = '.'.join(splitted[:-1]).upper().encode('ascii'), splitted[-1].upper()
        if len(name) > name_limit or len(suffix) > 3:
            raise RuntimeError(f'Filename {repr(f)} too long.')
        path = os.path.join(input_dir, f)
        filename_cache[(suffix, name)] = path
    # Sort by suffix then object name beforehand
    filename_cache = OrderedDict(sorted(filename_cache.items(), key=lambda e: e[0]))
    for sn, path in filename_cache.items():
        suffix, name = sn
        objects = metadata.get(suffix)
        if objects is None:
            objects = []
            metadata[suffix] = objects
        entry = ARCObjectEntry()
        entry.name = name
        entry.data_size = os.path.getsize(path)
        objects.append(entry)
    metadata_size = 4
    metadata_size += ctypes.sizeof(ARCTypeEntry) * len(metadata)
    for t in metadata.values():
        metadata_size += sum(ctypes.sizeof(obj) for obj in t)
    data_block_offset = metadata_size
    data_block_layout = []
    for type_, t in metadata.items():
        for obj in t:
            data_block_layout.append(filename_cache[(type_, obj.name)])
            obj.data_offset = data_block_offset
            data_block_offset += obj.data_size
    return metadata, data_block_layout

def write_metadata(arc, metadata):
    arc.write(len(metadata).to_bytes(4, 'little'))
    metadata_offset = 4 + ctypes.sizeof(ARCTypeEntry) * len(metadata)
    for type_, objects in metadata.items():
        type_entry = ARCTypeEntry()
        type_entry.name = type_.encode('ascii')
        type_entry.object_list_offset = metadata_offset
        type_entry.object_list_size = len(objects)
        metadata_offset += sum(ctypes.sizeof(obj) for obj in objects)
        arc.write(type_entry)
    for t in metadata.values():
        for obj in t:
            arc.write(obj)

def write_data_block(arc, layout):
    for fn in layout:
        with open(fn, 'rb') as f:
            arc.write(f.read())

def unpack(arc_path, output_dir, version=1):
    with open(arc_path, 'rb') as f:
        metadata = parse_metadata(f, version)
        dump_files(f, metadata, output_dir)

def pack(input_dir, arc_path, version=1):
    metadata, data_block_layout = build_metadata_from_files(input_dir, version)
    with open(arc_path, 'wb') as f:
        write_metadata(f, metadata)
        write_data_block(f, data_block_layout)

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('input_path', help='Path to input.')
    p.add_argument('output_path', help='Path to output.')
    p.add_argument('-c', '--create', action='store_true', help='Create archive.')
    p.add_argument('-x', '--extract', action='store_true', help='Extract archive.')
    p.add_argument('-v', '--version', type=int, default=1, help='Specify version (default to 1).')
    args = p.parse_args()
    if args.create and args.extract:
        p.error('Ambiguous operation.')
    elif not args.create and not args.extract:
        p.error('No operation specified.')
    return p, args

if __name__ == '__main__':
    p, args = parse_args()
    if args.create:
        pack(args.input_path, args.output_path, args.version)
    elif args.extract:
        unpack(args.input_path, args.output_path, args.version)
