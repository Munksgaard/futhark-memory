#!/usr/bin/env python3
#
# Print results from a JSON file

import json
import sys
import numpy as np
from collections import OrderedDict

def show(a):
    for k, v in a.items():
        v = v['runtimes']

        mean = np.mean(v)
        print(f'{k}: {mean:12.0f}μs (RSD: +/-{np.std(v) / mean:.3f}%; min: {(np.min(v) - mean) / mean * 100:.0f}%; max: {(np.max(v) - mean) / mean * 100:+.0f}%)')

if __name__ == '__main__':
    _, a_file = sys.argv

    a_json = json.load(open(a_file))

    show(a_json)
