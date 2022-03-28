#!/usr/bin/env python3
#
# Get benchmarks results from one benchmark
#
# USAGE: ./show-results results/a100/lud 32

import textwrap
import json
import sys
import numpy as np
import re
from collections import OrderedDict

def canonical_name(name):
    try:
        return str(max(list(map(int, re.findall(r'\d+', name)))))
    except:
        return list(filter(lambda x: x, name.split("/")))[-1]

def compare(name, reference, plain_json, mrg_json, short_json, combined_json):
    speedups = {}

    maxlen = max(map(lambda x: len(x), list(plain_json.keys())))

    print("""
\\begin{{table}}[!t]
  \\renewcommand{{\\arraystretch}}{{1.3}}
  \\caption{{{name} Performance ({num} runs)}}
  \\label{{tab:{name}-performance-32}}
  \\centering
  \\begin{{tabular}}{{c||c||c||c||c||c}}
    \\hline
    \\bfseries Dataset & \\bfseries Reference & \\bfseries \\thead{{Unopt. \\\\ Futhark}} & \\bfseries \\thead{{Opt. \\\\ Futhark}} & \\bfseries \\thead{{Opt. \\\\ Impact}} & \\bfseries Mem \\\\
    \\hline\\hline
""".format(name = name,
           num = len(list(plain_json.values())[0]["runtimes"])))

    for dataset, results in plain_json.items():
        pretty_name = canonical_name(dataset)

        ref = np.mean(reference[dataset]["runtimes"])
        print('    %% {name} & {reference_us} & {plain_us} & {combined_us} & {impact}\\\\\n'
              '    {name} & {reference:d}ms & {plain_speedup:.2f}x & {combined_speedup:.2f}x & {impact:.2f}x & {mem:+.0f}\\% \\\\'
              .format(name = pretty_name,
                      reference = int(round(ref / 100)),
                      reference_us = ref,
                      plain = int(round(np.mean(results["runtimes"]) / 1000)),
                      plain_us = np.mean(results["runtimes"]),
                      plain_speedup = ref / np.mean(results["runtimes"]),
                      combined = int(round(np.mean(combined_json[dataset]["runtimes"]) / 1000)),
                      combined_us = np.mean(combined_json[dataset]["runtimes"]),
                      combined_speedup = ref / np.mean(combined_json[dataset]["runtimes"]),
                      impact = np.mean(results["runtimes"]) / np.mean(combined_json[dataset]["runtimes"]),
                      mem = 100 - results["bytes"] / combined_json[dataset]["bytes"]  * 100))

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

    name = list(filter(lambda x: x, bench.split("/")))[-1]

    compare(name, reference, plain_json, mrg_json, short_json, combined_json)
