RUNS ?= 10

EXTERNALS_DIR = ../../../externals
FINPAR_DIR = $(EXTERNALS_DIR)/finpar
BENCH_DIR = $(FINPAR_DIR)/LocVolCalib/AllParOpenCLMP

results.json:
	make -C $(EXTERNALS_DIR) finpar.patched
	make -C $(BENCH_DIR) gpu
	for i in $(shell seq 0 $(RUNS)); do make -C $(BENCH_DIR) run_small; done \
	  | grep "Runtime in micro" \
	  | tail -n +2 \
	  | cut -f 1 \
	  | jq -nR '{"LocVolCalib-data/small.in": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  > $@

	for i in $(shell seq 0 $(RUNS)); do make -C $(BENCH_DIR) run_medium; done \
	  | grep "Runtime in micro" \
	  | tail -n +2 \
	  | cut -f 1 \
	  | jq -nR '{"LocVolCalib-data/medium.in": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	for i in $(shell seq 0 $(RUNS)); do make -C $(BENCH_DIR) run_large; done \
	  | grep "Runtime in micro" \
	  | tail -n +2 \
	  | cut -f 1 \
	  | jq -nR '{"LocVolCalib-data/large.in": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

clean:
	rm -f results.json
