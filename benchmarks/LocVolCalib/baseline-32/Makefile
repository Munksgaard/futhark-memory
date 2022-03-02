RUNS ?= 10

patched:
	patch -p1 -d finpar < finpar.patch
	touch $@

results.json: patched
	for i in $(shell seq 0 $(RUNS)); do make -C finpar/LocVolCalib/AllParOpenCLMP/ run_small; done \
	  | grep "Runtime in micro" \
	  | tail -n +2 \
	  | cut -f 1 \
	  | jq -nR '{"LocVolCalib-data/small.in": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  > $@

	for i in $(shell seq 0 $(RUNS)); do make -C finpar/LocVolCalib/AllParOpenCLMP/ run_medium; done \
	  | grep "Runtime in micro" \
	  | tail -n +2 \
	  | cut -f 1 \
	  | jq -nR '{"LocVolCalib-data/medium.in": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	for i in $(shell seq 0 $(RUNS)); do make -C finpar/LocVolCalib/AllParOpenCLMP/ run_large; done \
	  | grep "Runtime in micro" \
	  | tail -n +2 \
	  | cut -f 1 \
	  | jq -nR '{"LocVolCalib-data/large.in": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

	for i in $(shell seq 0 $(RUNS)); do make -C finpar/LocVolCalib/AllParOpenCLMP/ run_huge; done \
	  | grep "Runtime in micro" \
	  | tail -n +2 \
	  | cut -f 1 \
	  | jq -nR '{"LocVolCalib-data/huge.in": { "runtimes": [inputs | select(length>0) | tonumber]}}' \
	  | jq -s '.[0] + .[1]' - $@ \
	  | sponge $@

clean:
	rm -f results.json
