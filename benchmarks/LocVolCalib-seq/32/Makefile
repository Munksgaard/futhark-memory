FUTHARK ?= futhark
RUNS ?= 10

BENCHMARK ?= LocVolCalib.fut

EXTRA_DEPS =

OUTPUTS = plain.json memory-block-merging.json short-circuiting.json short-circuiting-no-merge.json

.PHONY: all
all: $(OUTPUTS)

plain.json: $(BENCHMARK) $(EXTRA_DEPS)
	$(FUTHARK) dev --gpu -a -e --cse -e --double-buffer -e --cse -e --expand-allocations -e --backend=opencl --server $<
	$(FUTHARK) bench --backend=opencl --pass-option=-P --skip-compilation --json $@ --runs $(RUNS) $<
	jq '."LocVolCalib.fut".datasets | map_values(del(.stderr)) | map_values(.bytes |= .device)' $@ \
	  | sponge $@

memory-block-merging.json: $(BENCHMARK) $(EXTRA_DEPS)
	$(FUTHARK) dev --gpu -a -e --cse -e --double-buffer -e --cse -e --memory-block-merging -e --expand-allocations -e --backend=opencl --server $<
	$(FUTHARK) bench --backend=opencl --pass-option=-P --skip-compilation --json $@ --runs $(RUNS) $<
	jq '."LocVolCalib.fut".datasets | map_values(del(.stderr)) | map_values(.bytes |= .device)' $@ \
	  | sponge $@

short-circuiting.json: $(BENCHMARK) $(EXTRA_DEPS)
	$(FUTHARK) dev --gpu -a -e --cse -e --double-buffer -e --cse --lift-allocations-gpu -e --short-circuit-gpu -e --cse -e --lower-allocations-gpu --cse -e --memory-block-merging -e --expand-allocations -e --backend=opencl --server $<
	$(FUTHARK) bench --backend=opencl --pass-option=-P --skip-compilation --json $@ --runs $(RUNS) $<
	jq '."LocVolCalib.fut".datasets | map_values(del(.stderr)) | map_values(.bytes |= .device)' $@ \
	  | sponge $@

short-circuiting-no-merge.json: $(BENCHMARK) $(EXTRA_DEPS)
	$(FUTHARK) dev --gpu -a -e --cse -e --double-buffer -e --cse --lift-allocations-gpu -e --short-circuit-gpu -e --cse -e --lower-allocations-gpu --cse -e -e --expand-allocations -e --backend=opencl --server $<
	$(FUTHARK) bench --backend=opencl --pass-option=-P --skip-compilation --json $@ --runs $(RUNS) $<
	jq '."LocVolCalib.fut".datasets | map_values(del(.stderr)) | map_values(.bytes |= .device)' $@ \
	  | sponge $@

clean:
	rm -f $(OUTPUTS)
