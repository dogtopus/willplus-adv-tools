#!/usr/bin/env python3

import argparse
import fnmatch
import json
import subprocess
import uuid
import os
import re
import sys
import tempfile

from concurrent import futures


FNMATCH_ESCAPE = re.compile(r'([\*\?\[\]])')


def _fnmatch_escape(filename):
    return FNMATCH_ESCAPE.sub(r'[\1]', filename)

def parse_args():
    p = argparse.ArgumentParser()
    p.add_argument('reference_file', help='Path to reference file.')
    p.add_argument('search_path', nargs='+', help='Search path. Multiple possible.')
    p.add_argument('-o', '--output-dir', help='Output directory.')
    p.add_argument('-w', '--wipf-py', default='./wipf.py', help='Specify wipf.py path (Defaults to ./wipf.py)')
    p.add_argument('-p', '--wipf-py-python-exe', default=sys.executable, help='Specify python runtime for wipf.py (Defaults to the same as we are using).')
    p.add_argument('-j', '--jobs', default=(os.cpu_count() or 1), help='Override number of parallel wipf.py jobs (Defaults to # of CPUs or 1 if cannot be determined).')
    return p, p.parse_args()

def find_files(search_paths, symbols):
    listings = {sp: os.listdir(sp) for sp in search_paths}
    for symbol in symbols:
        symbol_match = _fnmatch_escape(symbol)
        symbol_match = ''.join(f'[{c.upper()}{c.lower()}]' if c.isascii() and c.isalpha() else c for c in symbol_match)
        for prefix, files in listings.items():
            # Look for WIP first
            matches = fnmatch.filter(files, f'{symbol_match}.[Ww][Ii][Pp]')
            if len(matches) != 0:
                if len(matches) > 1:
                    print('** Case-insensitive match found more than 1 file. Selecting the first found.')
                yield symbol, os.path.join(prefix, matches[0])
                continue
            # Fallback to MSK if no WIP found
            matches = fnmatch.filter(files, f'{symbol_match}.[Mm][Ss][Kk]')
            if len(matches) != 0:
                if len(matches) > 1:
                    print('** Case-insensitive match found more than 1 file. Selecting the first found.')
                yield symbol, os.path.join(prefix, matches[0])
                continue

def process_file(tag, symbol, archive_name, in_path, out_path, rpy_path, wipf_py_python, wipf_py_path):
    args = (wipf_py_python,
            wipf_py_path,
            '--webp',
            '-M',
            '-r', os.path.join(rpy_path, f'{str(uuid.uuid1())}.rpy'),
            '-c', tag,
            '-p', archive_name,
            '-o', os.path.join(out_path, f'{symbol}_{{index}}.webp'),
            in_path,)

    print('==>', args)
    subprocess.run(args)

if __name__ == '__main__':
    p, args = parse_args()

    with open(args.reference_file, 'r') as f:
        refs = json.load(f)

    listing_dir = os.path.join(args.output_dir, 'Riopy', 'lists')
    os.makedirs(listing_dir, exist_ok=True)

    with tempfile.TemporaryDirectory() as work_dir:
        for tag, symbols in refs.items():
            print(f'=> Processing references for image tag {tag}...')
            rpy_path = os.path.join(work_dir, tag)

            os.makedirs(os.path.join(work_dir, tag), exist_ok=True)
            files = find_files(args.search_path, symbols)
            with futures.ThreadPoolExecutor(max_workers=args.jobs) as exe:
                for symbol, f in files:
                    prefix, _ = os.path.split(f)
                    archive_name = os.path.basename(os.path.abspath(prefix if len(prefix) != 0 else '.'))
                    out_path = os.path.join(args.output_dir, archive_name)
                    os.makedirs(out_path, exist_ok=True)
                    exe.submit(process_file, tag, symbol, archive_name, f, out_path, rpy_path, args.wipf_py_python_exe, args.wipf_py)
            print(f"==> Generating Ren'Py assets listing...")
            with open(os.path.join(listing_dir, f'{tag}list.rpy'), 'w') as rpy:
                rpy.write('init:\n')
                for fragfile in os.listdir(rpy_path):
                    with open(os.path.join(rpy_path, fragfile)) as rpyfrag:
                        for line in rpyfrag:
                            rpy.write(f'  {line}')

