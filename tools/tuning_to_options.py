#!/usr/bin/env python
#
# Reads on stdin JSON as produced by futhark-autotune, and prints on
# stdout it into command-line options that can be passed to
# futhark-bench.

import sys

for line in sys.stdin:
    if len(sys.argv) == 1:
        sys.stdout.write("--pass-option --size=%s " % line.strip())
    else:
        sys.stdout.write("--size=%s " % line.strip())
