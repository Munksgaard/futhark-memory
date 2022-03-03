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

    print('Baseline: plain')
    for dataset, results in plain_json.items():
        print('{name:12} '
              'plain: {plain_runtime:>12}µ, '
              'reference: {reference:>5.2f}x, '
              'mem block merge: {memblkmrg:>5.2f}x, '
              'short-circuit: {short:>5.2f}x, '
              'combined: {combined:5.2f}x'
              .format(name = textwrap.shorten(dataset, width=10) + ':',
                      plain_runtime = np.mean(results["runtimes"]),
                      reference = np.mean(results["runtimes"]) / np.mean(reference[dataset]["runtimes"]),
                      memblkmrg = np.mean(results["runtimes"]) / np.mean(mrg_json[dataset]["runtimes"]),
                      short = np.mean(results["runtimes"]) / np.mean(short_json[dataset]["runtimes"]),
                      combined = np.mean(results["runtimes"]) / np.mean(combined_json[dataset]["runtimes"])))

    print('')

    print('Baseline: reference')
    for dataset, results in plain_json.items():
        print('{name:12} '
              'plain: {plain:>5.2f}x, '
              'reference: {reference:>12}x, '
              'mem block merge: {memblkmrg:>5.2f}x, '
              'short-circuit: {short:>5.2f}x, '
              'combined: {combined:5.2f}x'
              .format(name = textwrap.shorten(dataset, width=10) + ':',
                      reference = np.mean(reference[dataset]["runtimes"]),
                      plain = np.mean(reference[dataset]["runtimes"]) / np.mean(results["runtimes"]),
                      memblkmrg = np.mean(reference[dataset]["runtimes"]) / np.mean(mrg_json[dataset]["runtimes"]),
                      short = np.mean(reference[dataset]["runtimes"]) / np.mean(short_json[dataset]["runtimes"]),
                      combined = np.mean(reference[dataset]["runtimes"]) / np.mean(combined_json[dataset]["runtimes"])))

if __name__ == '__main__':
    _, bench, bits = sys.argv

    reference = json.load(open(bench + '/baseline-' + bits + '/results.json'))
    plain_json = json.load(open(bench + '/' + bits + '/plain.json'))
    mrg_json = json.load(open(bench + '/' + bits + '/memory-block-merging.json'))
    short_json = json.load(open(bench + '/' + bits + '/short-circuiting-no-merge.json'))
    combined_json = json.load(open(bench + '/' + bits + '/short-circuiting.json'))

    compare(reference, plain_json, mrg_json, short_json, combined_json)
