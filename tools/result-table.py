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

def compare(name, reference, plain_json, mrg_json, short_json, combined_json):
    speedups = {}

    maxlen = max(map(lambda x: len(x), list(plain_json.keys())))

    print("""
\\begin{{table}}[!t]
  \\renewcommand{{\\arraystretch}}{{1.3}}
  \\caption{{{name} Runtime in Microseconds}}
  \\label{{tab:{name}-performance-32}}
  \\centering
  \\begin{{tabular}}{{c||c||c||c}}
    \\hline
    \\bfseries Dataset & \\bfseries Reference & \\bfseries Unoptimized Futhark & \\bfseries Optimized Futhark\\\\
    \\hline\\hline
""".format(name = name))

    for dataset, results in plain_json.items():
        ref = np.mean(reference[dataset]["runtimes"])
        print('    %% {name} & {reference} & {plain} & {combined} \\\\\n'
              '    {name} & {reference}ms & {plain_speedup:.2f}x & {combined_speedup:.2f}x \\\\'
              .format(name = dataset,
                      reference = ref,
                      plain = np.mean(results["runtimes"]),
                      plain_speedup = ref / np.mean(results["runtimes"]),
                      combined = np.mean(combined_json[dataset]["runtimes"]),
                      combined_speedup = ref / np.mean(combined_json[dataset]["runtimes"])))

    print("""
    \\hline
  \\end{tabular}
\\end{table}
""")

if __name__ == '__main__':
    _, bench = sys.argv

    bits = '32'

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

    name = bench.split("/")[-1]

    compare(name, reference, plain_json, mrg_json, short_json, combined_json)
