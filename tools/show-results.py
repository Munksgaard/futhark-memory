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

def compare(baseline, plain_json, mrg_json, short_json, combined_json):
    speedups = {}

    for dataset, results in sorted(plain_json.items(), key=lambda x: int(x[0])):
        print('{name:12} baseline: {plain_runtime:>12}µ. reference: {baseline:>5.2f}x, mem block merge: {memblkmrg:>5.2f}x ({memblkmrg_base:>4.2f}x), short-circuit: {short:>5.2f}x ({short_base:>4.2f}x), combined: {combined:5.2f}x ({combined_base:4.2f}x)'
                .format(name = textwrap.shorten(dataset, width=10) + ':',
                        plain_runtime = np.mean(results["runtimes"]),
                        baseline = np.mean(results["runtimes"]) / np.mean(baseline[dataset]["runtimes"]),
                        memblkmrg = np.mean(results["runtimes"]) / np.mean(mrg_json[dataset]["runtimes"]),
                        memblkmrg_base = np.mean(baseline[dataset]["runtimes"]) / np.mean(mrg_json[dataset]["runtimes"]),
                        short = np.mean(results["runtimes"]) / np.mean(short_json[dataset]["runtimes"]),
                        short_base = np.mean(baseline[dataset]["runtimes"]) / np.mean(short_json[dataset]["runtimes"]),
                        combined = np.mean(results["runtimes"]) / np.mean(combined_json[dataset]["runtimes"]),
                        combined_base = np.mean(baseline[dataset]["runtimes"]) / np.mean(combined_json[dataset]["runtimes"])))

if __name__ == '__main__':
    _, bench, bits = sys.argv

    baseline = json.load(open(bench + '/baseline-' + bits + '/results.json'))
    plain_json = json.load(open(bench + '/' + bits + '/plain.json'))
    mrg_json = json.load(open(bench + '/' + bits + '/memory-block-merging.json'))
    short_json = json.load(open(bench + '/' + bits + '/short-circuiting-no-merge.json'))
    combined_json = json.load(open(bench + '/' + bits + '/short-circuiting.json'))

    compare(baseline, plain_json, mrg_json, short_json, combined_json)
