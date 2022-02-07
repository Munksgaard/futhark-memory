FUTHARK ?= futhark
RUNS ?= 10

BENCHMARK ?= lud.fut

EXTRA_DEPS = lud-input.fut

OUTPUTS = plain.json memory-block-merging.json short-circuiting.json

.PHONY: all
all: $(OUTPUTS)

plain.json: $(BENCHMARK) $(EXTRA_DEPS)
	$(FUTHARK) dev --gpu -a -e --cse -e --double-buffer -e --cse -e --expand-allocations -e --backend=opencl --server $<
	$(FUTHARK) autotune --backend=opencl --tuning=plain.tuning --skip-compilation $(RUNS) $<
	$(FUTHARK) bench --backend=opencl --tuning=plain.tuning --skip-compilation --json $@ --runs $(RUNS) $<

memory-block-merging.json: $(BENCHMARK) $(EXTRA_DEPS)
	$(FUTHARK) dev --gpu -a -e --cse -e --double-buffer -e --cse -e --memory-block-merging -e --expand-allocations -e --backend=opencl --server $<
	$(FUTHARK) autotune --backend=opencl --tuning=memory-block-merging.tuning --skip-compilation $(RUNS) $<
	$(FUTHARK) bench --backend=opencl --tuning=memory-block-merging.tuning --skip-compilation --json $@ --runs $(RUNS) $<

short-circuiting.json: $(BENCHMARK) $(EXTRA_DEPS)
	$(FUTHARK) dev --gpu -a -e --cse -e --double-buffer -e --cse --lift-allocations-gpu -e --short-circuit-gpu -e --cse -e --lower-allocations-gpu --cse -e --memory-block-merging -e --expand-allocations -e --backend=opencl --server $<
	$(FUTHARK) autotune --backend=opencl --tuning=short-circuiting.tuning --skip-compilation $(RUNS) $<
	$(FUTHARK) bench --backend=opencl --tuning=short-circuiting.tuning --skip-compilation --json $@ --runs $(RUNS) $<

clean:
	rm -f $(OUTPUTS)
