#!/usr/bin/env python3
#
# Get benchmarks results from one benchmark
#
# USAGE: ./show-results results/a100/lud 32

import textwrap
import json
import sys
import numpy as np
from collections import OrderedDict

def compare(reference, plain_json, mrg_json, short_json, combined_json):
    speedups = {}

    maxlen = max(map(lambda x: len(x), list(plain_json.keys())))

    print('Baseline: none')
    for dataset, results in plain_json.items():
        if reference is None:
            ref = np.nan
        else:
            ref = np.mean(reference[dataset]["runtimes"])
        print('{name} '
              'plain: {plain_runtime:>12}µ, '
              'reference: {reference:>12}µ, '
              'mem block merge: {memblkmrg:>12}µ, '
              'short-circuit: {short:>12}µ, '
              'combined: {combined:12}µ'
              .format(name = (dataset + ':').ljust(maxlen+1),
                      plain_runtime = np.mean(results["runtimes"]),
                      reference = ref,
                      memblkmrg = np.mean(mrg_json[dataset]["runtimes"]),
                      short = np.mean(short_json[dataset]["runtimes"]),
                      combined = np.mean(combined_json[dataset]["runtimes"])))

    print('\nBaseline: plain')
    for dataset, results in plain_json.items():
        if reference is None:
            ref = np.nan
        else:
            ref = np.mean(reference[dataset]["runtimes"])
        print('{name} '
              'plain: {plain_runtime:>12}µ, '
              'reference: {reference:>5.2f}x, '
              'mem block merge: {memblkmrg:>5.2f}x, '
              'short-circuit: {short:>5.2f}x, '
              'combined: {combined:5.2f}x'
              .format(name = (dataset + ':').ljust(maxlen+1),
                      plain_runtime = np.mean(results["runtimes"]),
                      reference = np.mean(results["runtimes"]) / ref,
                      memblkmrg = np.mean(results["runtimes"]) / np.mean(mrg_json[dataset]["runtimes"]),
                      short = np.mean(results["runtimes"]) / np.mean(short_json[dataset]["runtimes"]),
                      combined = np.mean(results["runtimes"]) / np.mean(combined_json[dataset]["runtimes"])))

    if reference is None:
        return

    print('\nBaseline: reference')
    for dataset, results in plain_json.items():
        print('{name} '
              'plain: {plain:>5.2f}x, '
              'reference: {reference:>12}µ, '
              'mem block merge: {memblkmrg:>5.2f}x, '
              'short-circuit: {short:>5.2f}x, '
              'combined: {combined:5.2f}x'
              .format(name = (dataset + ':').ljust(maxlen+1),
                      reference = np.mean(reference[dataset]["runtimes"]),
                      plain = np.mean(reference[dataset]["runtimes"]) / np.mean(results["runtimes"]),
                      memblkmrg = np.mean(reference[dataset]["runtimes"]) / np.mean(mrg_json[dataset]["runtimes"]),
                      short = np.mean(reference[dataset]["runtimes"]) / np.mean(short_json[dataset]["runtimes"]),
                      combined = np.mean(reference[dataset]["runtimes"]) / np.mean(combined_json[dataset]["runtimes"])))

if __name__ == '__main__':
    _, bench, bits = sys.argv

    reference = None
    try:
        with open(bench + '/baseline-' + bits + '/results.json') as f:
            reference = json.load(f)
    except FileNotFoundError:
        pass


    with open(bench + '/' + bits + '/plain.json') as f:
        plain_json = json.load(f)

    with open(bench + '/' + bits + '/memory-block-merging.json') as f:
        mrg_json = json.load(f)

    with open(bench + '/' + bits + '/short-circuiting-no-merge.json') as f:
        short_json = json.load(f)

    with open(bench + '/' + bits + '/short-circuiting.json') as f:
        combined_json = json.load(f)

    compare(reference, plain_json, mrg_json, short_json, combined_json)
