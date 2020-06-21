#!/usr/bin/env python3
# Extract WillPlus image symbols from Ren'Py lint on op2rpy results.
import re
import json
import sys

NOT_AN_IMAGE_PATTERN = re.compile(r"rpy:\d+ '(.+)' is not an image\.$")
if __name__ == '__main__':
    extracted_references = 0
    image_references = 0
    lines = 0
    result = {}
    with open(sys.argv[1], 'r') as f:
        for line in f:
            lines += 1
            m = NOT_AN_IMAGE_PATTERN.search(line.rstrip())
            if m is not None:
                image_references += 1
                ref = m.group(1).split(' ')
                if len(ref) == 2:
                    tag = result.get(ref[0])
                    if tag is None:
                        tag = set()
                        result[ref[0]] = tag
                    tag.add(ref[1])
                    extracted_references += 1

    for k, v in result.items():
        result[k] = tuple(sorted(v))

    with open(sys.argv[2], 'w') as f:
        json.dump(result, f, sort_keys=True, indent=4, separators=(',', ': '))
    print(f'Processed {lines} lines and found {image_references} image references. {extracted_references} of these references are extracted.')
